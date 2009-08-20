#
# tempfile - manipulates temporary files
#
# $Id$
#

require 'delegate'
require 'tmpdir'
require 'thread'

module Better

# A utility class for managing temporary files. When you create a Tempfile
# object, it will create a temporary file with a unique filename. A Tempfile
# objects behaves just like a File object, and you can perform all the usual
# file operations on it: reading data, writing data, changing its permissions,
# etc. So although this class does not explicitly document all instance methods
# supported by File, you can in fact call any File instance method on a
# Tempfile object.
#
# == Synopsis
#
#  require 'better/tempfile'
#  
#  file = Better::Tempfile.new('foo')
#  file.path      # => A unique filename in the OS's temp directory,
#                 #    e.g.: "/tmp/foo.24722.0"
#                 #    This filename contains 'foo' in its basename.
#  file.write("hello world")
#  file.rewind
#  file.read      # => "hello world"
#  file.close
#  file.unlink    # deletes the temp file
#
# == Good practices
#
# === Explicit close
#
# When a Tempfile object is garbage collected, or when the Ruby interpreter
# exits, its associated temporary file is automatically deleted. This means
# that's it's unnecessary to explicitly delete a Tempfile after use, though
# it's good practice to do so: not explicitly deleting unused Tempfiles can
# potentially leave behind large amounts of tempfiles on the filesystem
# until they're garbage collected. The existance of these temp files can make
# it harder to determine a new Tempfile filename.
#
# Therefore, one should always call #unlink or close in an ensure block, like
# this:
#
#  file = Better::Tempfile.new('foo)
#  begin
#     ...do something with file...
#  ensure
#     file.close
#     file.unlink   # deletes the temp file
#  end
#
# === Unlink after creation
#
# On POSIX systems, it's possible to unlink a file right after creating it,
# and before closing it. This removes the filesystem entry without closing
# the file handle, so it ensures that only the processes that already had
# the file handle open can access the file's contents. It's strongly
# recommended that you do this if you do not want any other processes to
# be able to read from or write to the Tempfile, and you do not need to
# know the Tempfile's filename either.
#
# For example, a practical use case for unlink-after-creation would be this:
# you need a large byte buffer that's too large to comfortably fit in RAM,
# e.g. when you're writing a web server and you want to buffer the client's
# file upload data.
#
# Please refer to #unlink for more information and a code example.
#
# == Minor notes
#
# Tempfile is both thread-safe and inter-process-safe: when picking a temp
# filename, it guarantees that no other threads or processes will pick
# the same filename.
class Tempfile < DelegateClass(File)
  MAX_TRY = 10
  @@cleanlist = []
  @@lock = Mutex.new
  
  # Creates a temporary file of mode 0600 in the temporary directory,
  # opens it with mode "w+", and returns a Tempfile object which
  # represents the created temporary file.  A Tempfile object can be
  # treated just like a normal File object.
  #
  # The basename parameter is used to determine the name of a
  # temporary file.  If an Array is given, the first element is used
  # as prefix string and the second as suffix string, respectively.
  # Otherwise it is treated as prefix string.
  #
  # If tmpdir is omitted, the temporary directory is determined by
  # Dir::tmpdir provided by 'tmpdir.rb'.
  # When $SAFE > 0 and the given tmpdir is tainted, it uses
  # /tmp. (Note that ENV values are tainted by default)
  def initialize(basename, *rest)
    # I wish keyword argument settled soon.
    if rest.last.respond_to?(:to_hash)
      opts = rest.last.to_hash
      rest.pop
    else
      opts = nil
    end
    tmpdir = rest[0] || Dir::tmpdir
    if $SAFE > 0 and tmpdir.tainted?
      tmpdir = '/tmp'
    end

    lock = tmpname = nil
    n = failure = 0
    @@lock.synchronize {
      begin
        begin
          tmpname = File.join(tmpdir, make_tmpname(basename, n))
          lock = tmpname + '.lock'
          n += 1
        end while @@cleanlist.include?(tmpname) or
            File.exist?(lock) or File.exist?(tmpname)
        Dir.mkdir(lock)
      rescue
        failure += 1
        retry if failure < MAX_TRY
        raise "cannot generate tempfile `%s'" % tmpname
      end
    }

    @data = [tmpname]
    @clean_proc = self.class.callback(@data)
    ObjectSpace.define_finalizer(self, @clean_proc)

    if opts.nil?
      opts = []
    else
      opts = [opts]
    end
    @tmpfile = File.open(tmpname, File::RDWR|File::CREAT|File::EXCL, 0600, *opts)
    @tmpname = tmpname
    @@cleanlist << @tmpname
    @data[1] = @tmpfile
    @data[2] = @@cleanlist

    super(@tmpfile)

    # Now we have all the File/IO methods defined, you must not
    # carelessly put bare puts(), etc. after this.

    Dir.rmdir(lock)
  end

  def make_tmpname(basename, n)
    case basename
    when Array
      prefix, suffix = *basename
    else
      prefix, suffix = basename, ''
    end

    t = Time.now.strftime("%Y%m%d")
    path = "#{prefix}#{t}-#{$$}-#{rand(0x100000000).to_s(36)}-#{n}#{suffix}"
  end
  private :make_tmpname

  # Opens or reopens the file with mode "r+".
  def open
    @tmpfile.close if @tmpfile
    @tmpfile = File.open(@tmpname, 'r+')
    @data[1] = @tmpfile
    __setobj__(@tmpfile)
  end

  def _close	# :nodoc:
    @tmpfile.close if @tmpfile
    @tmpfile = nil
    @data[1] = nil if @data
  end
  protected :_close

  #Closes the file.  If the optional flag is true, unlinks the file
  # after closing.
  #
  # If you don't explicitly unlink the temporary file, the removal
  # will be delayed until the object is finalized.
  def close(unlink_now=false)
    if unlink_now
      close!
    else
      _close
    end
  end

  # Closes and unlinks the file.
  def close!
    _close
    @clean_proc.call
    ObjectSpace.undefine_finalizer(self)
    @data = @tmpname = nil
  end

  # Unlinks (deletes) the file from the filesystem. One should always unlink
  # the file after using it, as is explained in the "Explicit close" good
  # practice section in the Tempfile overview:
  #
  #  file = Better::Tempfile.new('foo)
  #  begin
  #     ...do something with file...
  #  ensure
  #     file.close
  #     file.unlink   # deletes the temp file
  #  end
  #
  # === Unlink-before-close
  #
  # On POSIX systems it's possible to unlink a file before closing it. This
  # practice is explained in detail in the Tempfile overview (section
  # "Unlink after creation"); please refer there for more information.
  #
  # However, unlink-before-close may not be supported on non-POSIX operating
  # systems. Microsoft Windows is the most notable case: unlinking a non-closed
  # file will result in an error, which this method will silently ignore. If
  # you want to practice unlink-before-close whenever possible, then you should
  # write code like this:
  #
  #  file = Better::Tempfile.new('foo')
  #  file.unlink   # On Windows this silently fails.
  #  begin
  #     ... do something with file ...
  #  ensure
  #     file.close!   # Closes the file handle. If the file wasn't unlinked
  #                   # because #unlink failed, then this method will attempt
  #                   # to do so again.
  #  end
  def unlink
    # keep this order for thread safeness
    begin
      if File.exist?(@tmpname)
        closed? or close
        unlink_file(@tmpname)
      end
      @@cleanlist.delete(@tmpname)
      @data = @tmpname = nil
      ObjectSpace.undefine_finalizer(self)
    rescue Errno::EACCES
      # may not be able to unlink on Windows; just ignore
    end
  end
  alias delete unlink
  
  def unlinked?
    @tmpname.nil?
  end

  # Returns the full path name of the temporary file.
  def path
    @tmpname
  end

  # Returns the size of the temporary file.  As a side effect, the IO
  # buffer is flushed before determining the size.
  def size
    if @tmpfile
      @tmpfile.flush
      @tmpfile.stat.size
    else
      0
    end
  end
  alias length size

  class << self
    def callback(data)	# :nodoc:
      pid = $$
      Proc.new {
	if pid == $$
	  path, tmpfile, cleanlist = *data

	  print "removing ", path, "..." if $DEBUG

	  tmpfile.close if tmpfile

	  # keep this order for thread safeness
	  File.unlink(path) if File.exist?(path)
	  cleanlist.delete(path) if cleanlist

	  print "done\n" if $DEBUG
	end
      }
    end

    # If no block is given, this is a synonym for new().
    #
    # If a block is given, it will be passed tempfile as an argument,
    # and the tempfile will automatically be closed when the block
    # terminates.  The call returns the value of the block.
    def open(*args)
      tempfile = new(*args)

      if block_given?
	begin
	  yield(tempfile)
	ensure
	  tempfile.close
	end
      else
	tempfile
      end
    end
  end
  
  private
    def unlink_file(filename)
      File.unlink(filename)
    end
end

end # module Better
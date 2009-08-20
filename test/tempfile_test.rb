require File.expand_path(File.join(File.dirname(__FILE__), "test_helper"))
require 'better/tempfile'

class TempfileTest < Test::Unit::TestCase
  include Better
  
  def teardown
    if @tempfile
      @tempfile.close if !@tempfile.closed?
      @tempfile.unlink if !@tempfile.unlinked?
    end
  end
  
  def test_basic
    @tempfile = Tempfile.new("foo")
    path = @tempfile.path
    @tempfile.write("hello world")
    @tempfile.close
    assert_equal "hello world", File.read(path)
  end
  
  def test_saves_in_tmpdir
    @tempfile = Tempfile.new("foo")
    assert_equal Dir.tmpdir, File.dirname(@tempfile.path)
  end
  
  def test_basename
    @tempfile = Tempfile.new("foo")
    assert_match /^foo/, File.basename(@tempfile.path)
  end
  
  def test_basename_with_suffix
    @tempfile = Tempfile.new(["foo", ".txt"])
    assert_match /^foo/, File.basename(@tempfile.path)
    assert_match /\.txt$/, File.basename(@tempfile.path)
  end
  
  def test_unlink_and_unlink_p
    @tempfile = Tempfile.new("foo")
    path = @tempfile.path
    assert !@tempfile.unlinked?
    
    @tempfile.close
    assert !@tempfile.unlinked?
    assert File.exist?(path)
    
    @tempfile.unlink
    assert @tempfile.unlinked?
    assert !File.exist?(path)
    
    @tempfile = nil
  end
  
  def test_unlink_makes_path_nil
    @tempfile = Tempfile.new("foo")
    @tempfile.close
    @tempfile.unlink
    assert_nil @tempfile.path
  end
  
  def test_unlink_silently_fails_on_windows
    tempfile = flexmock(Tempfile.new("foo"))
    path = tempfile.path
    begin
      tempfile.should_receive(:unlink_file).with(path).raises(Errno::EACCES)
      assert_nothing_raised do
        tempfile.unlink
      end
      assert !tempfile.unlinked?
    ensure
      tempfile.close
      File.unlink(path)
    end
  end
  
  def test_unlink_before_close_works_on_posix_systems
    tempfile = Tempfile.new("foo")
    begin
      path = tempfile.path
      tempfile.unlink
      if tempfile.unlinked?
        assert !File.exist?(path)
        tempfile.write("hello ")
        tempfile.write("world\n")
        tempfile.rewind
        assert_equal "hello world\n", tempfile.read
      end
    ensure
      tempfile.close
      tempfile.unlink if !tempfile.unlinked?
    end
  end
  
  def test_close_and_close_p
    @tempfile = Tempfile.new("foo")
    assert !@tempfile.closed?
    @tempfile.close
    assert @tempfile.closed?
  end
  
  def test_close_with_unlink_now_true_works
    @tempfile = Tempfile.new("foo")
    path = @tempfile.path
    @tempfile.close(true)
    assert @tempfile.closed?
    assert @tempfile.unlinked?
    assert_nil @tempfile.path
    assert !File.exist?(path)
  end
  
  def test_close_with_unlink_now_true_does_not_unlink_if_already_unlinked
    @tempfile = Tempfile.new("foo")
    path = @tempfile.path
    @tempfile.unlink
    File.open(path, "w").close
    begin
      @tempfile.close(true)
      assert File.exist?(path)
    ensure
      File.unlink(path) rescue nil
    end
  end
  
  def test_close_bang_works
    @tempfile = Tempfile.new("foo")
    path = @tempfile.path
    @tempfile.close!
    assert @tempfile.closed?
    assert @tempfile.unlinked?
    assert_nil @tempfile.path
    assert !File.exist?(path)
  end
  
  def test_close_bang_does_not_unlink_if_already_unlinked
    @tempfile = Tempfile.new("foo")
    path = @tempfile.path
    @tempfile.unlink
    File.open(path, "w").close
    begin
      @tempfile.close!
      assert File.exist?(path)
    ensure
      File.unlink(path) rescue nil
    end
  end
  
  def test_finalizer_does_not_unlink_if_already_unlinked
    filename = run_script("tempfile_explicit_close_and_unlink_example.rb").strip
    assert File.exist?(filename)
    
    filename = run_script("tempfile_explicit_unlink_example.rb").strip
    if !filename.empty?
      # POSIX unlink semantics supported, continue with test
      assert File.exist?(filename)
    end
  end
  
  def test_close_does_not_make_path_nil
    @tempfile = Tempfile.new("foo")
    @tempfile.close
    assert_not_nil @tempfile.path
  end
  
  def test_close_flushes_buffer
    @tempfile = Tempfile.new("foo")
    @tempfile.write("hello")
    @tempfile.close
    assert 5, File.size(@tempfile.path)
  end
  
  def test_tempfile_is_unlinked_when_ruby_exits
    filename = run_script("tempfile_unlink_on_exit_example.rb").strip
    assert !File.exist?(filename)
  end
  
  def test_size_flushes_buffer_before_determining_file_size
    @tempfile = Tempfile.new("foo")
    @tempfile.write("hello")
    assert 0, File.size(@tempfile.path)
    assert 5, @tempfile.size
    assert 5, File.size(@tempfile.path)
  end
  
  def test_size_works_if_file_is_closed
    @tempfile = Tempfile.new("foo")
    @tempfile.write("hello")
    @tempfile.close
    assert 5, @tempfile.size
  end
  
  if defined?(Encoding)
    def test_tempfile_encoding_nooption
      default_external = Encoding.default_external
      t = Tempfile.new("TEST")
      t.write("\xE6\x9D\xBE\xE6\xB1\x9F")
      t.rewind
      assert_equal(default_external, t.read.encoding)
    end
    
    def test_tempfile_encoding_ascii8bit
      default_external = Encoding.default_external
      t = Tempfile.new("TEST", :encoding => "ascii-8bit")
      t.write("\xE6\x9D\xBE\xE6\xB1\x9F")
      t.rewind
      assert_equal(Encoding::ASCII_8BIT, t.read.encoding)
    end
    
    def test_tempfile_encoding_ascii8bit2
      default_external = Encoding.default_external
      t = Tempfile.new("TEST", Dir::tmpdir, :encoding => "ascii-8bit")
      t.write("\xE6\x9D\xBE\xE6\xB1\x9F")
      t.rewind
      assert_equal(Encoding::ASCII_8BIT, t.read.encoding)
    end
  end
end


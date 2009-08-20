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
    tempfile = flexmock(Better::Tempfile.new("foo"))
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
  
  def test_close_and_close_p
    @tempfile = Tempfile.new("foo")
    assert !@tempfile.closed?
    @tempfile.close
    assert @tempfile.closed?
  end
  
  def test_close_does_not_make_path_nil
    @tempfile = Tempfile.new("foo")
    @tempfile.close
    assert_not_nil @tempfile.path
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


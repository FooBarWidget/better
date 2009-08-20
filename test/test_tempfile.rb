require File.expand_path(File.join(File.dirname(__FILE__), "test_helper"))
require 'better/tempfile'

class TestTempfile < Test::Unit::TestCase
  include Better
  
  def teardown
    if @tempfile
      @tempfile.close if !@tempfile.closed?
      @tempfile.unlink
    end
  end
  
  def test_basic
    @tempfile = Better::Tempfile.new("foo")
    path = @tempfile.path
    @tempfile.write("hello world")
    @tempfile.close
    assert_equal "hello world", File.read(path)
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


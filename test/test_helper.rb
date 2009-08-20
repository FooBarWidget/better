$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), "..", "lib")))
require 'rubygems'
require 'test/unit'
require 'rbconfig'
require 'better/tempfile'

require 'flexmock/test_unit'  # Because Mocha can't stub DelegateClass objects for some reason.
if !defined?(Test::Unit::AssertionFailedError)
  # Flexmock on the other hand is broken on Ruby 1.9 so we fix it by
  # monkeypatching it here. Sigh....
  Test::Unit.class_eval do
    AssertionFailedError = MiniTest::Assertion
  end
end

def run_script(script, *args)
  output = Better::Tempfile.new('output')
  begin
    output.close
    
    ruby = File.join(Config::CONFIG['bindir'], Config::CONFIG['ruby_install_name']) + Config::CONFIG['EXEEXT']
    command = [ruby, File.join(File.dirname(__FILE__), script), output.path, *args]
    
    if system(*command)
      File.read(output.path)
    else
      raise "Command failed: #{command.join(' ')}"
    end
  ensure
    output.close if !output.closed?
    output.unlink
  end
end
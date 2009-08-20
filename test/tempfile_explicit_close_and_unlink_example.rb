require File.expand_path(File.join(File.dirname(__FILE__), "example_helper"))
require 'better/tempfile'

file = Better::Tempfile.new('foo')
path = file.path
puts path
file.close!
File.open(path, "w").close
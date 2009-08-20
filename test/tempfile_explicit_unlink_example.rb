require File.expand_path(File.join(File.dirname(__FILE__), "example_helper"))
require 'better/tempfile'

file = Better::Tempfile.new('foo')
path = file.path
file.unlink
if file.unlinked?
  puts path
  File.open(path, "w").close
else
  file.close!
end
require File.expand_path(File.join(File.dirname(__FILE__), "example_helper"))
require 'better/tempfile'

puts Better::Tempfile.new('foo').path
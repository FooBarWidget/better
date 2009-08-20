require 'better/tempfile'
Object.send(:remove_const, :Tempfile) if defined?(Tempfile)
::Tempfile = Better::Tempfile
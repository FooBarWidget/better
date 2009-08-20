$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), "..", "lib")))
require 'rubygems'
require 'test/unit'
require 'flexmock/test_unit'  # Because Mocha can't stub DelegateClass objects for some reason.
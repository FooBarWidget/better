Gem::Specification.new do |s|
  s.name = "better"
  s.version = "1.0.0"
  s.summary = "Collection of better replacements for Ruby standard libraries"
  s.email = "hongli@phusion.nl"
  s.homepage = "http://better.rubyforge.org/"
  s.description = "Collection of better replacements for Ruby standard libraries."
  s.has_rdoc = true
  s.rubyforge_project = "better"
  s.authors = ["Hongli Lai"]
  
  s.files = [
      "README.rdoc", "LICENSE", "better.gemspec", "Rakefile",
      "lib/better/tempfile.rb",
      "lib/better/override/tempfile.rb",
      "test/test_helper.rb",
      "test/example_helper.rb",
      "test/tempfile_test.rb",
      "test/tempfile_explicit_close_and_unlink_example.rb",
      "test/tempfile_explicit_unlink_example.rb",
      "test/tempfile_unlink_on_exit_example.rb"
  ]
end

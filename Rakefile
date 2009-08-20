begin
  require 'rubygems'
  require 'hanna/rdoctask'
rescue LoadError
  STDERR.puts "*** Warning: you do not have the Hanna rdoc template installed. The rdoc will look better if you do. You should type:"
  STDERR.puts "  sudo gem sources -a http://gems.github.com"
  STDERR.puts "  sudo gem install mislav-hanna"
  STDERR.puts
  require 'rake/rdoctask'
end
require 'rake/testtask'

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.title = "Better: API documentation"
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
  rd.rdoc_dir = "doc"
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end
begin
  require 'rubygems'
  require 'hanna/rdoctask'
rescue Gem::LoadError
  STDERR.puts "*** Warning: you do not have the Hanna rdoc template installed. The rdoc will look better if you do. You should type:"
  STDERR.puts "  sudo gem sources -a http://gems.github.com"
  STDERR.puts "  sudo gem install mislav-hanna"
  require 'rdoc/rdoctask'
end

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.title = "The Better library"
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
  rd.rdoc_dir = "doc"
end
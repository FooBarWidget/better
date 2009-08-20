$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), "..", "lib")))
output_file = ARGV.shift
STDOUT.reopen(output_file, "w")
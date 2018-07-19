require_relative 'sql_database/sql_database'

ROOT = Dir.pwd
services = []

# All for different args to run individual services or all of them
if ARGV.empty?
  puts "No arguments specified. Running all of services."
  services = Dir["#{ROOT}/*/"].map{ |path| path.split('/').last }
else
  ARGV.each do |service|
    if Dir.exists?("#{ROOT}/#{service}")
      services << service unless service == 'sql_database'
    else
      puts "SKIPPING: No directory found for #{service}. Expected ./#{service}/#{service}.rb"
    end
  end
end

services.each do |service|
  executable = "#{ROOT}/#{service}/#{service}.rb"
  if File.exists?(executable)
    require executable
    clazz_name = service.gsub(/\s/, '').split(/_|\-/).to_a.reduce(''){ |out, part| out + part.capitalize }
    clazz = Object.const_get(clazz_name)
    obj = clazz.new
    if obj.respond_to?(:process)
      puts "Running #{service}"
      puts "---------------------------------------"
      SqlDatabase.process(service, obj.send(:process))
      puts "Done\n"
    else
      puts "SKIPPING: No method called 'process' found for #{service}"
    end
  else
    puts "SKIPPING: No executable found for #{service}. Expected ./#{service}/#{service}.rb"
  end
end

require 'yaml'

require_relative 'lib/database/session'
require_relative 'lib/database/nodes/project'

ROOT = Dir.pwd
CONFIG = YAML.load(File.read("#{ROOT}/config/database.yml")).symbolize_keys
services = []

# All for different args to run individual services or all of them
if ARGV.empty?
  puts "No arguments specified. Running all of services."
  services = Dir["#{ROOT}/*/"].map{ |path| path.split('/').last }
else
  ARGV.each do |service|
    if Dir.exists?("#{ROOT}/lib/services/#{service}")
      services << service unless service == 'sql_database'
    else
      puts "SKIPPING: No directory found for #{service}. Expected ./lib/services/#{service}/#{service}.rb"
    end
  end
end

@session = Database::Session.new(CONFIG.fetch(:neo4j, {}).symbolize_keys)

# Testing
project = Database::Project.new(session: @session, title: 'Testing', description: 'Blah blah blah', identifiers: ['a', 'b', 'c'], random: 'value')
puts project.serialize_attributes

loaded = Database::Project.find(@session, '42dc3caa8407d8115c67729a67cc58e8')

puts project.save

services.each do |service|
  executable = "#{ROOT}/lib/services/#{service}/#{service}.rb"
  if File.exists?(executable)
    require executable
    clazz_name = service.gsub(/\s/, '').split(/_|\-/).to_a.reduce(''){ |out, part| out + part.capitalize }
    clazz = Object.const_get(clazz_name)
    obj = clazz.new
    if obj.respond_to?(:process)
      puts "Running #{service}"
      puts "---------------------------------------"
      json = obj.send(:process)

      json[:projects].each do |project|
        puts "    Processing - `#{project[:title]}`"
        project = Database::Project.new(project.merge({ session: @session }))
        puts project.serialize_attributes
        project.save
        puts "    -------"
      end

      puts "Done\n"
    else
      puts "SKIPPING: No method called 'process' found for #{service}"
    end
  else
    puts "SKIPPING: No executable found for #{service}. Expected ./#{service}/#{service}.rb"
  end
end

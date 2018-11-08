require 'yaml'

require_relative 'lib/database/session'
require_relative 'lib/database/nodes/project'

ROOT = Dir.pwd
CONFIG = YAML.load(File.read("#{ROOT}/config/database.yml")).symbolize_keys
debug, services = false, []

# All for different args to run individual services or all of them
if ARGV.empty?
  puts "No arguments specified. Running all of services."
  services = Dir["#{ROOT}/lib/services/*/"].map{ |path| path.split('/').last }
else
  ARGV.each do |service|
    if service == 'debug'
      debug = true
    else
      if Dir.exists?("#{ROOT}/lib/services/#{service}")
        services << service
      else
        puts "SKIPPING: No directory found for #{service}. Expected #{ROOT}/lib/services/#{service}/"
      end
    end
  end
end

@session = Database::Session.new(CONFIG.fetch(:neo4j, {}).symbolize_keys.merge({debug: debug}))

services.each do |service|
  executable = "#{ROOT}/lib/services/#{service}/#{service}.rb"
  if File.exists?(executable)
    require executable
    clazz_name = service.gsub(/\s/, '').split(/_|\-/).to_a.reduce(''){ |out, part| out + part.capitalize }
    clazz = Object.const_get(clazz_name)
    obj = clazz.new({ session: @session, mysql: CONFIG.fetch(:mysql, {}) })
    if obj.respond_to?(:process)
      puts "Running #{service}"
      puts "---------------------------------------"
      json = obj.send(:process)

      json[:projects].each_with_index do |project, idx|
        puts "  -------------------------------------" unless idx == 0
        puts "  Loading - `#{project[:title]}`"
        result = Database::Project.find_or_create(project.merge({ session: @session, source: service }))
        result.save(project.merge(session: @session, source: service))
      end

      puts "---------------------------------------"
      puts "Done\n"
    else
      puts "SKIPPING: No method called 'process' found for #{service}"
    end
  else
    puts "SKIPPING: No executable found for #{service}. Expected #{ROOT}/lib/services/#{service}/#{service}.rb"
  end
end

require_relative 'db'
require_relative 'helpers'
Dir["#{Dir.pwd}/sql_database/models/*.rb"].each{ |file| require file }

class SqlDatabase
  def self.process(service, json)
    source = Source.find_by(name: service)

    if source.present? && json[:projects].present? && json[:projects].length > 0
      json[:projects].each_with_index do |project_hash, idx|
        unless project_hash['error_code'].present?
          project_hash[:source_id] = source.id

          # Attempt to find the project. If it does not exist create it
          puts "  Processing project #{idx}: #{project_hash[:title]}"
          project = Project.find_or_create_by_hash(project_hash)
          puts "  Done!"
          project
        end
      end
    else
      puts "  Nothing to load to the database for #{service}"
    end
  end
end

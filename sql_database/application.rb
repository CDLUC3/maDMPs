require 'mysql2'
require_relative 'source'
require_relative 'project'
require_relative 'expedition'
require_relative 'author'
require_relative 'helpers'

db = Mysql2::Client.new(host: "localhost", username: "root", database: 'maDMPs')
sources = Source.all(db)

if sources.count <= 0
  puts "You do not have any sources defined!"
else
  sources.each do |source|
    if !source.downloader.nil?
      puts "Downloading latest metadata from #{source.name}"

if source.name == 'BCO-DMO'
      json = source.downloader.send('download')

      # Exclusion lists are meant to truncate incoming JSON structures
      # so that only the info relevant to the current object is included
      # in the source_json stored in the table (e.g. projects.source_json
      # does not store all of its expeditions JSON. That info is instead
      # stored in expeditions.source_json)
      project_json_exclusions = source.downloader.send(:get_project_exclusions)
      expedition_json_exclusions = source.downloader.send(:get_expedition_exclusions)

      # Identifiers are the unique keys the source uses to identify a project
      project_identifiers = source.downloader.send(:get_project_identifiers)
      expedition_identifiers = source.downloader.send(:get_expedition_identifiers)
      author_identifiers = source.downloader.send(:get_author_identifiers)

      if json[:projects].length > 0
        json[:projects].each do |project_json|
          project_hash = prepare_json(project_json, project_json_exclusions)
          project_hash[:source_id] = source.id

          # Attempt to find the project. If it does not exist create it
          puts "  Processing project: #{project_hash[:title]}"
          project = Project.find(db, project_hash)
          if project.nil?
            project_id = Project.create!(db, project_hash)
          else
            project_id = project.id
          end

          # Process any expeditions
          unless project_json[:expeditions].nil?
            project_json[:expeditions].each do |expedition_json|
              hash = {
                source_id: source.id,
                project_id: project_id,
                title: expedition_json[:expeditionTitle],
                ts: expedition_json[:ts],
                public: expedition_json[:public],
                identifiers: collect_identifiers(expedition_json, expedition_identifiers),
                source_json: prepare_json(expedition_json, expedition_json_exclusions)
              }

              puts "    Processing expedition: #{hash[:title]}"
              expedition = Expedition.find(db, expedition_json)
              if expedition.nil?
                expedition_id = Expedition.create!(db, hash)
              else
                expedition_id = expedition.id
              end

              # Create any authors
              unless expedition_json[:user].nil?
                auth_hash = {
                  source_id: source.id,
                  project_id: project_id,
                  expedition_id: expedition_id,
                  name: expedition_json[:user]['username'],
                  pi: expedition_json[:user]['projectAdmin'],
                  identifiers: collect_identifiers(expedition_json[:user], author_identifiers)
                }
                if !auth_hash[:name].nil? || at_least_one?(auth_hash[:identifiers])
                  puts "      Processing researcher: #{auth_hash[:name]} (ids: [#{auth_hash[:identifiers].join(', ')}])"
                  author = Author.find(db, auth_hash)
                  if author.nil?
                    author_id = Author.create!(db, auth_hash) if author.nil?
                  end
                end
              end
            end
          end
        end
      end
    else
      puts "Skipping #{source.name} because its downloader application is undefined or missing."
    end

end

  end
end
db.close

Dir["#{Dir.pwd}/*.rb", "#{Dir.pwd}/models/*.rb"].each {|file| require file unless file.end_with?('application.rb') }
sources = Source.all

if sources.count <= 0
  puts "You do not have any sources defined!"
else
  sources.each do |source|
    if !source.downloader.nil?
      puts "Downloading latest metadata from #{source.name}"

if source.name == 'Biocode' #'BCO-DMO'
      json = source.downloader.send('download')

      if json[:projects].length > 0
        json[:projects].each do |project_hash|
          project_hash[:source_id] = source.id

          # Attempt to find the project. If it does not exist create it
          puts "  Processing project: #{project_hash[:title]}"
          project = Project.find_or_create_by_hash(project_hash)

puts project

          # Process any expeditions
=begin
          unless project_hash[:expeditions].nil?
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
=end
        end
      else 
        puts "  Nothing to process"
      end
end

    else
      puts "Skipping #{source.name} because its downloader application is undefined or missing."
    end

  end
end

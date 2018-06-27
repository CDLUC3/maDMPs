require 'mysql2'
require_relative 'source'
require_relative 'project'

# --------------------------------------------------------------
extract_obj_json = Proc.new{ |obj, exclusions| obj.select{ |k,v| !exclusions.include?(k) }.to_json }

# --------------------------------------------------------------
identifiers_to_array = Proc.new{ |id_list, obj| id_list.map{ |id| obj["#{id.to_s}"] } }

# --------------------------------------------------------------
process_expedition = Proc.new do |downloader, source, expedition|
  ids = identifiers_to_array.call(downloader.send(:get_expedition_identifiers), expedition)
  sel = db.prepare(
    "SELECT expeditions.id \
     FROM expeditions \
     LEFT OUTER JOIN expedition_identifiers ON expeditions.id = expedition_identifiers.expedition_id \
     WHERE (expeditions.id = ? AND expeditions.source_id = ?)")

  # Insert the expedition record if it does not exist
  exp = sel.execute(expedition['expeditionId'], source['id'])
  if exp.count <= 0
    ins = db.prepare(
      "INSERT INTO expeditions (title, start_date, public, source_id, source_json) VALUES (?, ?, ?, ?, ?)"
    )
    ins.execute(expedition['expeditionTitle'], expedition['ts'], expedition['public'] || 0, source['id'], extract_obj_json.call(expedition, downloader.send(:get_expedition_exclusions)))
    exp = sel.execute(expedition['expeditionId'], source['id']).first
  else
    exp = exp.first
  end
  exp
end

# --------------------------------------------------------------
require_relative 'helpers'

db = Mysql2::Client.new(host: "localhost", username: "root", database: 'maDMPs')
sources = Source.all(db)

if sources.count <= 0
  puts "You do not have any sources defined!"
else
  sources.each do |source|
    if !source.downloader.nil?
      puts "Downloading latest metadata from #{source.name}"
      json = source.downloader.send('download')

      # Exclusion lists are meant to truncate incoming JSON structures
      # so that only the info relevant to the current object is included
      # in the source_json stored in the table (e.g. projects.source_json
      # does not store all of its expeditions JSON. That info is instead
      # stored in expeditions.source_json)
      project_json_exclusions = source.downloader.send(:get_project_exclusions)

      # Identifiers are the unique keys the source uses to identify a project
      project_identifiers = source.downloader.send(:get_project_identifiers)

      if json[:projects].length > 0
        json[:projects].each do |project_json|
          hash = {
            source_id: source.id,
            title: project_json['projectTitle'],
            identifiers: collect_identifiers(project_json, project_identifiers),
            markers: project_json[:markers] || [],
            expeditions: [],
            source_json: prepare_json(project_json, project_json_exclusions)
          }
          # Attempt to find the project. If it does not exist create it
          puts "  Processing project: #{hash[:title]}"
          project = Project.find(db, hash)
          if project.nil?
            project_id = Project.create!(db, hash)
            project = Project.find(db, { id: project_id })
          end
        end
      end
    else
      puts "Skipping #{source.name} because its downloader application is undefined or missing."
    end
  end
end
db.close

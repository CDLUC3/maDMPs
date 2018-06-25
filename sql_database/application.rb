require 'mysql2'
require_relative './project'

db = Mysql2::Client.new(host: "localhost", username: "root", database: 'maDMPs')
sources = db.query('SELECT * FROM sources')

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
process_project = Proc.new do |downloader, source, project|
  ids = identifiers_to_array.call(downloader.send(:get_project_identifiers), project)
  ps = db.prepare(
    "SELECT projects.id \
     FROM projects \
     LEFT OUTER JOIN project_identifiers ON projects.id = project_identifiers.project_id \
     WHERE (projects.title = ? AND projects.source_id = ?)")

  # Insert the project record if it does not exist
  prj = ps.execute(project['projectTitle'], source['id'])
  if prj.count <= 0
    ins_p = db.prepare(
      "INSERT INTO projects (title, source_id, source_json) VALUES (?, ?, ?)")
    ins_p.execute(project['projectTitle'], source['id'], extract_obj_json.call(project, downloader.send(:get_project_exclusions)))
    prj = ps.execute(project['projectTitle'], source['id']).first
  else
    prj = prj.first
  end

  # insert project identifiers
  ids.each do |id|
    pids = db.prepare(
      "SELECT id FROM project_identifiers WHERE identifier = ? AND project_id = ?"
    )
    if pids.execute(id, prj['id']).count <= 0
      ins_pid = db.prepare(
        "INSERT INTO project_identifiers (source_id, project_id, identifier) VALUES (?, ?, ?)"
      )
      ins_pid.execute(source['id'], prj['id'], id)
    end
  end

  # Process expeditions
  unless project[:expeditions].nil?
    project[:expeditions].each do |expedition|
      exp = process_expedition.call(downloader, source, expedition)
      if exp.present?
        ins_e = db.prepare("INSERT INTO project_expeditions (project_id, expedition_id, source_id) VALLUES (?, ?, ?)")
        ins_e.execute(prj['id'], exp['id'], source['id'])
      end
    end
  end
end

# --------------------------------------------------------------
if sources.count <= 0
  puts "You do not have any sources defined!"
else
  sources.each do |source|
    if source['directory']
      path = File.expand_path("..", Dir.pwd)
      path += "/#{source['directory']}"
      Dir["#{path}/*.rb"].each {|file| require file }

      puts "Downloading data from #{source['name'].capitalize}"
      clazz = Object.const_get("#{source['name'].capitalize}")
      obj = clazz.new
      if obj.respond_to?('download')
        json = obj.send('download')

        if json[:projects].length > 0
          json[:projects].each do |project_json|
            project = Project.new({ conn: db, source: source, json: project_json })
            project.save! if project.respond_to?(:save) && project.valid? 

            #process_project.call(obj, source, project)
          end
        end
      end
    else
      puts "Skipping #{source['name']} because its downloader application is undefined or missing."
    end
  end
end
db.close

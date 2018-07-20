# This is a utility script to query the BCO-DMO metadata sent via email
require 'json'

class BcoDmo
  # CONSTANTS
  BASE_DIR = "#{ROOT}/bco_dmo/tmp"
  SOURCE = "#{BASE_DIR}/bco_dmo.json"
  OUTPUT = "#{BASE_DIR}/output.json"

  def process
    if !File.exists?(SOURCE)
      puts "  SKIPPING: bco_dmo - You must retrieve the BCO-DMO json query (currently emailed) and place it into #{SOURCE}."
    else
      puts "  Converting raw BCO-DMO JSON in #{SOURCE} to a standard JSON format."
      download
    end
  end

  def get_project_identifiers
    [:projectId, :projectAlternateName]
  end

  def get_metadata
    file = File.read(SOURCE)
    if file
      begin
        json = JSON.parse(file)
        if json['result'].nil?
          puts "    Expected the JSON input to follow the BCO-DMO search results format. Expected the project results to be in json['result']!"
          nil
        else
          json['result']
        end
      rescue Exception => e
        puts "    Invalid JSON found at #{SOURCE}"
        nil
      end
    end
  end

  # Converts the json received from BCO-DMO into our generic json format
  def download
    projects, json = [], get_metadata

    json.each do |project|
      proj_types, proj_ids = [], []
      proj_types << project['@type'] unless project['@type'].nil?
      proj_types << project['additionalType'] unless project['additionalType'].nil?
      proj_ids << project['@id'] unless project['@id'].nil?
      proj_ids << project['alternateName'] unless project['alternateName'].nil?

      contributors = []
      unless project['contributor'].nil?
        project['contributor'].each do |contrib_hash|
          contributors << {
            name: contrib_hash['contributor']['name'],
            identifiers: [contrib_hash['contributor']['@id']],
            role: contrib_hash['roleName'],
            org: { name: contrib_hash['odo:forOrganization']['name']}
          }
        end
      end

      awards = []

      unless project['funder'].nil? || project['funder'][project['funder'].keys.first]['makesOffer'].nil?
        org_hash = {
          types: [project['funder'][project['funder'].keys.first]['@type']],
          identifiers: [project['funder'][project['funder'].keys.first]['@id']],
          name: project['funder'][project['funder'].keys.first]['name']
        }

        project['funder'][project['funder'].keys.first]['makesOffer'].each do |offer|
          award_ids = [offer['@id'], offer['name'], offer['sameAs']]
          awards << {
            org: org_hash,
            title: offer['name'],
            identifiers: award_ids.select{|a| a.present? },
            offered_by: { name: offer['offeredBy']['name'], identifiers: [offer['offeredBy']['@id']], role: offer['offeredBy']['additionalType']}
          }
        end
      end

      documents = []
      unless project['odo:hasDataManagementPlan'].nil?
        project['odo:hasDataManagementPlan'].each do |dmp|
          documents << {
            types: [dmp['description'], dmp['encodingFormat']] || [],
            title: dmp['description'] || nil,
            identifiers: [dmp['url']] || []
          }
        end
      end

      projects << {
        identifiers: proj_ids,
        types: proj_types,
        title: project['name'],
        description: project['description'],
        contributors: contributors,
        awards: awards,
        documents: documents
      }
    end

    { projects: projects }
  end

  # Converts the json received from BCO-DMO into our generic json format
  def download_to_file
    dir = "#{File.expand_path("..", Dir.pwd)}/bco_dmo/tmp"
    Dir.mkdir(BASE_DIR) unless File.exists?(BASE_DIR)
    File.open(OUTPUT, 'w') do |file|
      file.write(JSON.pretty_generate(download))
    end
  end
end

#app = BcoDmo.new
#app.download_to_file

# This is a utility script to query the Geome-db FIMS database for analysis that was
# based on the R scripts provided by DIPnet: https://github.com/DIPnet/fimsR-access
require 'json'
require 'uri'
require 'net/http'

class Geome
  # CONSTANTS
  BASE_DIR = "#{ROOT}/geome/tmp"
  OUTPUT = "#{BASE_DIR}/output.json"
  MIN_PROJECT, MAX_PROJECT = 1, 51
  FIMS_ROOT_URL = "https://www.geome-db.org/rest/"
  FIMS_EXPEDITION_PATH = "projects/%{project_id}/expeditions"
  FIMS_QUERY_PATH = "projects/query/fastq"
  FIMS_FASTA_QUERY_PATH = "projects/query/fasta"
  FIMS_FASTA_MARKER_PATH = "projects/%{project_id}/config/lists/markers/fields"

  def process()
    puts "  Retrieving project metadata from the Geome API at: #{FIMS_ROOT_URL}."
    download
  end

  def get_project_identifiers
    [:projectId, :projectCode]
  end
  def get_expedition_identifiers
    [:expeditionId, :expeditionCode, :expeditionBcid, :entityBcids]
  end
  def get_author_identifiers
    [:userId]
  end

  # JSON fields to skip when inserting source_json
  def get_project_exclusions
    [:expeditions, :markers]
  end
  def get_marker_exclusions
    []
  end
  def get_expedition_exclusions
    [:user]
  end

  # Expecting an array of expeditions in the following JSON format:
  #  {"expeditionId"=>431,
  #   "expeditionCode"=>"acaach_CyB_JD",
  #   "expeditionTitle"=>"acaach_CyB_JD spreadsheet",
  #   "ts"=>"2016-12-16 19:18:51",
  #   "project"=>{
  #     "projectId"=>25,
  #     "projectCode"=>"DIPNET",
  #     "projectTitle"=>"DIPNet"
  #   },
  #   "user"=>{
  #     "userId"=>145,
  #     "username"=>"dipnetCurator",
  #     "projectAdmin"=>false
  #   },
  #   "expeditionBcid"=>nil,
  #   "entityBcids"=>nil,
  #   "public"=>true}
  def get_expeditions(project_id, limit=10)
    uri = URI("#{FIMS_ROOT_URL}#{FIMS_EXPEDITION_PATH}".gsub('%{project_id}', project_id.to_s))
    puts "    Getting Expeditions for Project #{project_id}: #{uri}"
    res = Net::HTTP.get(uri)
    case res
      when Net::HTTPSuccess then 
        JSON.parse(res)
      when Net::HTTPRedirection then 
        get_expeditions(res['location'], limit - 1)
      else
        puts "      #{res}"
        []
      end
  end

  # Expecting an array of markers in the following JSON format:
  #  {"uri"=>nil,
  #   "value"=>"CYB",
  #   "defined_by"=>nil,
  #   "definition"=>"mitochondrial cytocrhome B"}
  def get_markers(project_id)
    uri = URI("#{FIMS_ROOT_URL}#{FIMS_FASTA_MARKER_PATH}".sub('%{project_id}', project_id.to_s))
    puts "    Getting FASTA Markers: #{uri}"
    res = Net::HTTP.get(uri)
    JSON.parse(res)
  end

  def prepare_query(expeditions, query)
    "#{query}+_expeditions_:{#{expeditions.join(',')}}"
  end

  # @param expeditions list of expeditions to include in the query. The default is all expeditions
  # @param names       list of column names to include in the data.frame results
  # @param query       FIMS Query DSL \url{http://fims.readthedocs.io/en/latest/fims/query.html} query string.
  #                    Ex. '+locality:fuzzy +country:"exact phrase"'
  def query_metadata(expeditions, query, names=nil)
    query_string = prepare_query(expeditions, query)
    uri = URI("#{FIMS_ROOT_URL}#{FIMS_QUERY_PATH}/#{query_string}")
    res = Net::HTTP.get(uri)
    if res.status == 204
      puts "    No samples found"
    else
      # Grab the uri of the CSV file and download it
      JSON.parse(res)
    end
  end

  def query_fasta(marker, expeditions, names=nil)
    query_string = prepare_query(expeditions, query)
    res = Net::HTTP.get("#{FIMS_ROOT_URL}#{FIMS_FASTA_QUERY_PATH}/#{query_string} +fastaSequence.marker:#{marker}")
    if res.status == 204
      puts "    No samples found"
    else
      # Grab the uri of the CSV file and download it
      puts res.body
    end
  end

  #expeditions = get_expeditions
  #markers = get_markers(PROJECT_ID)
  def download
    projects = (MIN_PROJECT..MAX_PROJECT).map do |project_id|
      expeditions = get_expeditions(project_id)
      project, proj_ids = {}, [project_id]

      if expeditions.is_a?(Array) && expeditions.length > 0 && expeditions[0]['project'].is_a?(Hash)
        project = expeditions[0]['project']
        proj_ids << project['projectCode'] unless project['projectCode'].nil?

        project = {
          identifiers: proj_ids,
          title: project['projectTitle'] || ''
        }

        markers = get_markers(project_id)
        project[:markers] = markers.nil? ? [] : markers.is_a?(Array) ? markers : [markers]

        project[:documents] = expeditions.map do |expedition|
          exp_ids = []
          exp_ids << expedition['expeditionId'] unless expedition['expeditionId'].nil?
          exp_ids << expedition['expeditionCode'] unless expedition['expeditionCode'].nil? || expedition['expeditionCode'] == ''
          exp_ids << expedition['expeditionTitle'] unless expedition['expeditionTitle'].nil?
          exp_ids << expedition['expeditionBcid'] unless expedition['expeditionBcid'].nil? || expedition['expeditionBcid'] == ''
          exp_ids << expedition['entityBcids'] unless expedition['entityBcids'].nil? || expedition['entityBcids'] == ''

          #user_hash = {
          #  identifiers: [expedition['userId']].compact,
          #  name: expedition['username'] || '',
          #  role: expedition['projectAdmin'] || 'false'
          #}

          {
            source: 'geome',
            identifiers: exp_ids,
            types: ['Dataset'],
            title: expedition['expeditionTitle'] || '',
            #start_date: expedition['ts'] || Time.now.to_s,
            #contributors: (user_hash[:identifiers].empty? && user_hash[:name] == '' ? [] : [user_hash]),
            #public: expedition['public'] || 'true'
          }
        end
      elsif expeditions.length > 0
        project['error_code'] = expeditions['httpStatusCode']
        project['error_msg'] = expeditions['usrMessage']
      else
        project['error_code'] = 500
        project['error_msg'] = "The API returned a Success code but the array was empty."
      end
      project
    end

    { projects: projects }
  end

  def download_to_file
    Dir.mkdir(BASE_DIR) unless File.exists?(BASE_DIR)
    File.open(OUTPUT, 'w') do |file|
      file.write(JSON.pretty_generate(download))
    end
  end
end

#app = Geome.new
#app.download_to_file

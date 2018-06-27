# This is a utility script to query the Geome-db FIMS database for analysis that was
# based on the R scripts provided by DIPnet: https://github.com/DIPnet/fimsR-access
require 'json'
require 'uri'
require 'net/http'

class Geome
  # CONSTANTS
  #PROJECT_ID = 25
  FIMS_ROOT_URL = "https://www.geome-db.org/rest/"
  FIMS_EXPEDITION_PATH = "projects/%{project_id}/expeditions"
  FIMS_QUERY_PATH = "projects/query/fastq"
  FIMS_FASTA_QUERY_PATH = "projects/query/fasta"
  FIMS_FASTA_MARKER_PATH = "projects/%{project_id}/config/lists/markers/fields"

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
  def get_expeditions(project_id)
    uri = URI("#{FIMS_ROOT_URL}#{FIMS_EXPEDITION_PATH}".gsub('%{project_id}', project_id.to_s))
    puts "Getting Expeditions for Project #{project_id}: #{uri}"
    res = Net::HTTP.get(uri)
    JSON.parse(res)
  end

  # Expecting an array of markers in the following JSON format:
  #  {"uri"=>nil,
  #   "value"=>"CYB",
  #   "defined_by"=>nil,
  #   "definition"=>"mitochondrial cytocrhome B"}
  def get_markers(project_id)
    uri = URI("#{FIMS_ROOT_URL}#{FIMS_FASTA_MARKER_PATH}".sub('%{project_id}', project_id.to_s))
    puts "Getting FASTA Markers: #{uri}"
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
      puts "No samples found"
    else
      # Grab the uri of the CSV file and download it
      JSON.parse(res)
    end
  end

  def query_fasta(marker, expeditions, names=nil)
    query_string = prepare_query(expeditions, query)
    res = Net::HTTP.get("#{FIMS_ROOT_URL}#{FIMS_FASTA_QUERY_PATH}/#{query_string} +fastaSequence.marker:#{marker}")
    if res.status == 204
      puts "No samples found"
    else
      # Grab the uri of the CSV file and download it
      puts res.body
    end
  end

  #expeditions = get_expeditions
  #markers = get_markers(PROJECT_ID)
  def download
    projects = (1..30).map do |project_id|
      expeditions = get_expeditions(project_id)
      project = { projectId: project_id }

      if expeditions.is_a?(Array) && expeditions.length > 0 && expeditions[0]['project'].is_a?(Hash)
        project = expeditions[0]['project']
        project_json = {
          projectCode: project['projectCode'] || '',
          projectTitle: project['projectTitle'] || ''
        }

        markers = get_markers(project_id)
        project[:markers] = markers.nil? ? [] : markers.is_a?(Array) ? markers : [markers]

        project[:expeditions] = expeditions.map do |expedition|
          {
            expeditionId: expedition['expeditionId'] || '',
            expeditionCode: expedition['expeditionCode'] || '',
            expeditionTitle: expedition['expeditionTitle'] || '',
            ts: expedition['ts'] || Time.now.to_s,
            user: {
              userId: expedition['userId'] || '',
              username: expedition['username'] || '',
              projectAdmin: expedition['projectAdmin'] || 'false'
            },
            expeditionBcid: expedition['expeditionBcid'] || '',
            entityBcids: expedition['entityBcids'] || '',
            public: expedition['public'] || 'true'
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
    dir = "#{Dir.pwd}/tmp"
    Dir.mkdir(dir) unless File.exists?(dir)
    File.open("#{dir}/output.json", 'w') do |file|
      file.write(JSON.pretty_generate(download))
    end
  end

  #puts markers

  #res = query_metadata([431], 'polynesia')
  #puts res
end

require 'json'
require 'nokogiri'

# For use with the Berkeley Biocode Metadata in EML format
#   http://bnhmipt.berkeley.edu/ipt/resource?r=biocode

class Biocode
  BASE_DIR = "#{ROOT}/lib/services/biocode/tmp"
  SOURCE = "#{BASE_DIR}/biocode.xml"
  OUTPUT = "#{BASE_DIR}/output.json"

  def process
    if !File.exists?(SOURCE)
      puts "  SKIPPING: biocode - You must manually download the Biocode EML file from http://bnhmipt.berkeley.edu/ipt/resource?r=biocode and place it into #{SOURCE}."
    else
      puts "  Converting raw Biocode EML in #{SOURCE} to a standard JSON format."
      download
    end
  end

  def load_eml
    doc = File.open(SOURCE) { |f| Nokogiri::XML(f) }
  end

  #expeditions = get_expeditions
  #markers = get_markers(PROJECT_ID)
  def download
    xml = load_eml.xpath('//eml:eml//dataset')
    unless xml.nil?
      bounding_coords = "Geographic Boundary - Northern #{xml.xpath('coverage/geographicCoverage/boundingCoordinates/northBoundingCoordinate').text}, Eastern #{xml.xpath('coverage/geographicCoverage/boundingCoordinates/eastBoundingCoordinate').text}, Southern #{xml.xpath('coverage/geographicCoverage/boundingCoordinates/southBoundingCoordinate').text}, Western #{xml.xpath('coverage/geographicCoverage/boundingCoordinates/westBoundingCoordinate').text}"
      contribs = []
      contribs << {
        identifiers: [xml.xpath('creator/electronicMailAddress').text],
        name: "#{xml.xpath('creator/individualName/givenName').text} #{xml.xpath('creator/individualName/surName').text}",
        email: xml.xpath('creator/electronicMailAddress').text,
        role: xml.xpath('creator/positionName').text,
        org: { name: xml.xpath('creator/organizationName').text }
      }
      contribs << {
        identifiers: [xml.xpath('metadataProvider/electronicMailAddress').text],
        name: "#{xml.xpath('metadataProvider/individualName/givenName').text} #{xml.xpath('creator/individualName/surName').text}",
        email: xml.xpath('metadataProvider/electronicMailAddress').text,
        role: xml.xpath('metadataProvider/positionName').text,
        org: { name: xml.xpath('metadataProvider/organizationName').text }
      }
      project_json = {
        source: 'biocode',
        identifiers: xml.xpath('alternateIdentifier').map{ |id| id.text },
        title: xml.xpath('title').text,
        license: xml.xpath('intellectualRights/para').text,
        description: "#{xml.xpath('abstract/para').text}<br/>&nbsp;Coverage Area: #{xml.xpath('coverage/geographicCoverage/geographicDescription.text')}<br/>&nbsp;&nbsp;#{bounding_coords}",
        publication_date: xml.xpath('pubDate').text,
        language: xml.xpath('language').text,
        contributors: contribs
      }
    end

    { projects: [project_json || nil] }
  end

  def download_to_file
    Dir.mkdir(BASE_DIR) unless File.exists?(BASE_DIR)
    File.open(OUTPUT, 'w') do |file|
      file.write(JSON.pretty_generate(download))
    end
  end
end

#app = Biocode.new
#app.download_to_file

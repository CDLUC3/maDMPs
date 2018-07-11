require 'json'
require 'nokogiri'

# For use with the Berkeley Biocode Metadata in EML format
#   http://bnhmipt.berkeley.edu/ipt/resource?r=biocode

class Biocode
  def load_eml
    dir = "#{File.expand_path("..", Dir.pwd)}/biocode/tmp/biocode.xml"
    doc = File.open(dir) { |f| Nokogiri::XML(f) }
  end

  #expeditions = get_expeditions
  #markers = get_markers(PROJECT_ID)
  def download
    xml = load_eml.xpath('//eml:eml//dataset')
    unless xml.nil?
      bounding_coords = "Geographic Boundary - Northern #{xml.xpath('coverage/geographicCoverage/boundingCoordinates/northBoundingCoordinate').text}, Eastern #{xml.xpath('coverage/geographicCoverage/boundingCoordinates/eastBoundingCoordinate').text}, Southern #{xml.xpath('coverage/geographicCoverage/boundingCoordinates/southBoundingCoordinate').text}, Western #{xml.xpath('coverage/geographicCoverage/boundingCoordinates/westBoundingCoordinate').text}"
      contribs = []
      contribs << {
        name: "#{xml.xpath('creator/individualName/givenName').text} xml.xpath('creator/individualName/surName').text",
        email: xml.xpath('creator/electronicMailAddress').text,
        role: xml.xpath('creator/positionName').text,
        org: { name: xml.xpath('creator/organizationName').text }
      }
      contribs << {
        name: "#{xml.xpath('metadataProvider/individualName/givenName').text} xml.xpath('creator/individualName/surName').text",
        email: xml.xpath('metadataProvider/electronicMailAddress').text,
        role: xml.xpath('metadataProvider/positionName').text,
        org: { name: xml.xpath('metadataProvider/organizationName').text }
      }
      project_json = {
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
    dir = "#{File.expand_path("..", Dir.pwd)}/biocode/tmp"
    Dir.mkdir(dir) unless File.exists?(dir)
    File.open("#{dir}/output.json", 'w') do |file|
      file.write(JSON.pretty_generate(download))
    end
  end
end

#app = Biocode.new
#app.download_to_file

# NSF Awards API docs: https://www.research.gov/common/webapi/awardapisearch-v1.htm
# Expecting the following format from NSF:
#
#  {
#  "response" : {
#    "award" : [ {
#      "agency" : "NSF",
#      "awardeeCity" : "Somewhere",
#      "awardeeName" : "University of Somewhere",
#      "awardeeStateCode" : "CA",
#      "fundsObligatedAmt" : "1234",
#      "id" : "0000012",
#      "piFirstName" : "John",
#      "piLastName" : "Doe",
#      "publicAccessMandate" : "0",
#      "date" : "08/12/2014",
#      "title" : "An interesting project title"
#    },

require 'date'
require 'json'
require 'uri'
require 'net/http'
require_relative '../helpers/words'

class Nsf
  include Words

  ROOT_URL = 'https://api.nsf.gov/services/v1/awards'
  SCAN_THRESHOLD = 7 #days

  def process
    min_date = (Date.today - SCAN_THRESHOLD)
    source = Source.find_by(name: 'nsf')
    puts "  Retrieving award metadata from the NSF API at: #{ROOT_URL}."

    Project.includes(:api_scans, [contributors: :orgs]).limit(2).each do |project|
      scan = project.api_scans.where(source_id: source.id).first
      if !scan.present? || scan.last_scan <= min_date
        download(source.id, project)
      end
    end
  end

  def download(source_id, project)
    words = Words.cleanse(project.title)
    prj_contributors = project.contributors
    prj_orgs = prj_contributors.collect{ |c| c.orgs }.flatten.uniq

    unless words.empty?
      json = []
      base_uri = "#{ROOT_URL}.json?keyword=#{words.join('%20')}"
      puts "    Searching NSF for project '#{project.title}'"
      res = Net::HTTP.get(URI(base_uri))
      json << JSON.parse(res)

      if json.length > 0 && json.first['response'].present?
        json.first['response']['award'][0..1].each do |award|
          if award['awardeeName'].present? && award['piLastName'].present?
            puts "      NSF found award: '#{award['title']}'"

            potential_org = Org.fuzzy_find(prj_orgs, {
              source_id: source_id,
              name: award['awardeeName'],
              city: award['awardeeCity'],
              state: award['awardeeStateCode']
            })
            potential_contributor = Contributor.fuzzy_find(prj_contributors, {
              source_id: source_id,
              name: "#{award['piFirstName']} #{award['piLastName']}"
            })

            if Words.match?(project.title, award['title'])
              if potential_org.id.present? || potential_contributor.id.present?
                if potential_org.id.present?
                  puts "      Verified award with match on '#{potential_org.name}' (#{potential_org.id})"
                else
                  puts "      Unable to match Org: '#{potential_org.name}'"
                end
                if potential_contributor.id.present?
                  puts "      Verified award with match on '#{potential_contributor.name}' (#{potential_contributor.id})"
                else
                  puts "      Unable to match Contributor: '#{potential_contributor.name}'"
                end
              else
                puts "      Unable to verify matching Org or Contributor for '#{award['title']}'"
              end
              puts JSON.pretty_generate(award)
            else
              puts "      Award title does not match project title: '#{award['title']}'"
            end
          end
          puts "-----------------------------------------------"
        end
      end
    else
      []
    end
  end

  def processOrg(source_id, all_orgs, award_json)
    matches = all_orgs.select{ |org| Words.match?(award_json['awardeeName'], org.name) }
    # If no Org was found go ahead and add it to the DB
    if matches.empty?
      matches = [Org.find_or_create_by_hash!(
        source_id: source_id,
        name: award_json['awardeeName'],
        city: award_json['awardeeCity'],
        state: award_json['awardeeStateCode']
      )]
    end
    matches.flatten!
  end

  def processContributor(source_id, all_contribs, award_json)
    name = "#{award_json['piFirstName']} #{award_json['piLastName']}"
    matches = all_contribs.select{ |contrib| Words.match?(name, contrib.name) }
    # If no Contrib was found go ahead and add it to the DB
    if matches.empty?
      matches = [Contributor.fuzzy_find(all_contribs, name)]
    end
    matches.flatten!
  end

  def processAward(source_id, org, contributor, award_json)
    Award.find_or_create_by_hash!({
      source_id: source_id,
      title: award_json['title'],
      amount: award_json['fundsObligatedAmt'],
      public_access_mandata: award_json['publicAccessMandate'],
      identifiers: [award_json['id']]
    })
  end
end


#      "agency" : "NSF",
#      "awardeeCity" : "Somewhere",
#      "awardeeName" : "University of Somewhere",
#      "awardeeStateCode" : "CA",
#      "fundsObligatedAmt" : "1234",
#      "id" : "0000012",
#      "piFirstName" : "John",
#      "piLastName" : "Doe",
#      "publicAccessMandate" : "0",
#      "date" : "08/12/2014",
#      "title" : "An interesting project title"

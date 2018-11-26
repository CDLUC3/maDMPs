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

require_relative '../../database/session'
require_relative '../../database/cypher_helper'
require_relative '../../database/nodes/award'
require_relative '../../database/nodes/org'
require_relative '../../database/nodes/person'

class Nsf
  include Database::CypherHelper

  ROOT_URL = 'https://api.nsf.gov/services/v1/awards'
  SCAN_THRESHOLD = 7 #days

  def initialize(params)
    @source = 'nsf'
    @session = params.fetch(:session, nil)

    org_hash = { session: @session, source: @source, name: cypher_safe('National Science Foundation') }
    @org = Database::Org.find_or_create(org_hash)
    @org.save(org_hash)
  end

  def process()
    puts "Searching for available projects ..."

    scannable_projects.each do |project|
      words = [project.title, project_identifiers(project.uuid)].flatten.uniq.join(' ')
      keywords = Words.cleanse(words)

      awards = call_api(project, keywords)
    end

    # Return an empty json array since this service saves directly to the DB right now
    { projects: [] }
  end

  def scannable_projects
    min_date = Date.today - SCAN_THRESHOLD
    results = @session.cypher_query(
      "MATCH (p:Project) \
       WHERE (p.last_nsf_scan IS NULL OR p.last_nsf_scan < 'cypher_safe(#{min_date.to_s})') \
       RETURN p"
    )

    if results.any? && results.rows.length > 0 && results.rows.first.is_a?(Array)
      results.rows.map{ |row| Database::Project.cypher_response_to_object(row[0]) }
    else
      []
    end
  end

  def project_identifiers(project_id)
    results = @session.cypher_query(
      "MATCH (i:Identifier)-[:IDENTIFIES]-> (p:Project) \
       WHERE p.uuid = '#{cypher_safe(project_id.to_s)}' \
       RETURN i"
    )
    if results.any? && results.rows.length > 0 && results.rows.first.is_a?(Array)
      results.rows.map{ |row| row[0].props[:value] }
    else
      []
    end
  end

  def call_api(project, keywords)
    json = []
    uri = URI("#{ROOT_URL}.json?keyword=#{keywords.join('%20')}")

    puts "    Searching NSF for project '#{project.title}'"
    res = Net::HTTP.get(uri)
    begin
      json << JSON.parse(res)
    rescue Exception
      puts "    Unable to process the JSON response from the API!"
    end

    if json.length > 0 && json.first['response'].present?
      json.first['response']['award'][0..5].each do |award|
        process_award(project, award)
      end
    else
      puts "    No awards found"
    end

    @session.cypher_query(
      "MATCH (p:Project {uuid: '#{cypher_safe(project.uuid)}'}) \
       SET p.last_nsf_scan = '#{cypher_safe(Date.today.to_s)}'"
    )
  end

  def process_award(project, award)
    # First verify that the Award title is similar to the project title
    if Words.match_percent((cleanse_nsf_title(award['title'])), project.title) > 0.8
      obj = award_from_hash!(award)

      # Now that we have awards lets check the PI name to see if we can
      # verify that its for this project
      contrib = person_from_hash!(award)

      puts "Saving (:Project)-[:RECEIVED]->(:Award)" if @session.debugging?
      @session.cypher_query(cypher_relate(project, obj, 'RECEIVED', { source: @source }))
      puts "Saving (:Person)-[:CONTRIBUTES_TO]->(:Project)" if @session.debugging?
      @session.cypher_query(cypher_relate(contrib, project, 'CONTRIBUTES_TO', { source: @source }))
    end
  end

  def award_from_hash!(hash)
    params = {
      session: @session,
      source: @source,
      title: cypher_safe(cleanse_nsf_title(hash['title'])),
      identifiers: [cypher_safe(hash['id'])],
      amount: cypher_safe(hash['fundsObligatedAmt']),
      date: cypher_safe(hash['date']),
      public_access_mandate: cypher_safe(hash['publicAccessMandate']),
      org: { name: cypher_safe(hash['agency']) }
    }
    title_parts = hash['title'].split(':')
    if title_parts.length > 1
      params[:types] = title_parts[0..title_parts.length - 1]
    end
    award = Database::Award.find_or_create(params)
    puts "Saving (:Award)" if @session.debugging?
    award.save(params)

    if hash['agency'].present?
      puts "Saving (:Org)-[:FUNDED]->(:Award)" if @session.debugging?
      @session.cypher_query(cypher_relate(@org, award, 'FUNDED', { source: @source }))
    end
    award
  end

  def person_from_hash!(hash)
    params = {
      session: @session,
      source: @source,
      name: cypher_safe("#{hash['piFirstName']} #{hash['piLastName']}")
    }
    contributor = Database::Person.find_or_create(params)
    puts "Saving (:Person)" if @session.debugging?
    contributor.save(params)

    if hash['awardeeName'].present?
      org_params = {
        session: @session,
        source: @source,
        name: cypher_safe(hash['awardeeName']),
        city: cypher_safe(hash['awardeeCity']),
        state: cypher_safe(hash['awardeeStateCode'])
      }
      org = Database::Org.find_or_create(org_params)
      puts "Saving (:Org)" if @session.debugging?
      org.save(org_params)

      puts "Saving (:Person)-[:AFFILIATED_WITH]->(:Org)" if @session.debugging?
      @session.cypher_query(cypher_relate(contributor, org, 'AFFILIATED_WITH', { source: @source }))
    end
    contributor
  end

  def cleanse_nsf_title(value)
    # removes NSF categorizations from title e.g.:
    #   original: 'EAGER: Collaborative Research: Exploratory application of single-molecule real time (SMRT) DNA sequencing in microbial ecology research'
    #   becomes: 'Exploratory application of single-molecule real time (SMRT) DNA sequencing in microbial ecology research'

    value.split(':').last
  end
end

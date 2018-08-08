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
require_relative '../nosql_database/cypher_helper'
require_relative '../nosql_database/nosql_database'

class Nsf
  include CypherHelper

  ROOT_URL = 'https://api.nsf.gov/services/v1/awards'
  SCAN_THRESHOLD = 7 #days

  def initialize
    @source = 'nsf-awards-api'
    @session = NosqlDatabase.new.session
  end

  def process()
    puts "Searching for available projects ..."

    scannable_projects.each do |project|
      words = [project[:title], project_identifiers(project[:madmp_id])].flatten.uniq.join(' ')
      keywords = Words.cleanse(words)

      awards = call_api(project, keywords)
    end
  end

  def scannable_projects
    min_date = Date.today - SCAN_THRESHOLD
    results = @session.query(
      "MATCH (p:Project) \
       WHERE p.last_nsf_scan IS NULL OR p.last_nsf_scan < 'cypher_safe(#{min_date.to_s})' \
       AND (p.title =~ '.*Biocode.*' OR p.title =~ '.*Moorea.*')
       RETURN p"
    )

    if results.any? && results.rows.length > 0 && results.rows.first.is_a?(Array)
      results.rows.map{ |row| row[0].props.select{ |k,v| k != :description } }
    else
      []
    end
  end

  def project_identifiers(project_id)
    results = @session.query(
      "MATCH (i:Identifier)-[:IDENTIFIES]-> (p:Project) \
       WHERE p.madmp_id = '#{cypher_safe(project_id.to_s)}' \
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

    puts "    Searching NSF for project '#{project[:title]}'"
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

    @session.query(
      "MATCH (p:Project {madmp_id: '#{cypher_safe(project[:madmp_id])}'}) \
       SET p.last_nsf_scan = '#{cypher_safe(Date.today.to_s)}'"
    )
  end

  def process_award(project, award)
    puts "      Received award: '#{award['title']}'"
    # First verify that the Award title is similar to the project title
    if Words.match_percent(award['title'], project[:title]) > 0.8
      award_id = award_from_hash!(award)

      # Now that we have awards lets check the PI name to see if we can
      # verify that its for this project
      name = cypher_safe("#{award['piFirstName']} #{award['piLastName']}")
      contribs = @session.query(
        "MATCH (p:Project {madmp_id: '#{cypher_safe(project[:madmp_id])}'})<-[r:CONTRIBUTED_TO]-(u:Person)-[:MEMBER_OF]->(o:Org) \
         WHERE u.name =~ '.*#{name}.*' \
         OR u.name =~ '.*#{cypher_safe(award['piLastName'])}.*' \
         RETURN u, o")

      # If any contributors were found we should also verify that their
      # Org matches the Org in the award
      if contribs.any? && contribs.rows.length > 0 && contribs.rows.first.is_a?(Array)
        contribs.rows.each do |row|
          if row.length > 1
            if Words.match_percent(award['awardeeName'], row[1].props[:name]) > 0.8
              contrib_id = row[0].props[:madmp_id]
              puts "        Award title and PI match! Updating award information"

              @session.query(
                "MATCH (p:Project {madmp_id: '#{cypher_safe(project[:madmp_id])}'}) \
                 MATCH (a:Award {madmp_id: '#{cypher_safe(award_id)}'}) \
                 MERGE (a)-[r:PRESENTED_TO]->(p) \
                 FOREACH(s IN CASE WHEN '#{@source}' IN r.sources THEN [] ELSE [1] END | SET r.sources = coalesce(r.sources, []) + '#{@source}')"
              )
            end
          end
        end
      else
        puts "        Award title matched project but contributor is unknown"
        contrib_id = person_from_hash!(award)
        @session.query(
          "MATCH (p:Project {madmp_id: '#{cypher_safe(project[:madmp_id])}'}) \
           MATCH (u:User {madmp_id: '#{cypher_safe(contrib_id)}'}) \
           MATCH (a:Award {madmp_id: '#{cypher_safe(award_id)}'}) \
           MERGE (a)-[r:PRESENTED_TO]->(p) \
           MERGE (u)-[r2:CONTRIBUTED_TO]->(p) \
           FOREACH(s IN CASE WHEN '#{@source}' IN r.sources THEN [] ELSE [1] END | SET r.sources = coalesce(r.sources, []) + '#{@source}') \
           FOREACH(s2 IN CASE WHEN '#{@source}' IN r2.sources THEN [] ELSE [1] END | SET r2.sources = coalesce(r2.sources, []) + '#{@source}')"
        )
      end
    else
      puts "        Award title does not match project title!"
    end
  end

  def award_from_hash!(hash)
    award_id = node_from_hash!({
      name: cypher_safe(hash['title']),
      identifiers: [cypher_safe(hash['id'])],
      amount: cypher_safe(hash['fundsObligatedAmt']),
      date: cypher_safe(hash['date']),
      public_access_mandate: cypher_safe(hash['publicAccessMandate']),
      org: { name: cypher_safe(hash['agency']) }
    }, 'Award', 'name')

    if hash['agency'].present?
      org_id = node_from_hash!({ name: cypher_safe(hash['agency']) }, 'Org', 'name')
      @session.query(
        "MATCH (a:Award {madmp_id: '#{award_id}'}) \
         MATCH (o:Org {madmp_id: '#{org_id}'}) \
         MERGE (o)-[r:FUNDED]->(a) \
         FOREACH(s IN CASE WHEN '#{@source}' IN r.sources THEN [] ELSE [1] END | SET r.sources = coalesce(r.sources, []) + '#{@source}')")
    end
    award_id
  end

  def person_from_hash!(hash)
    contributor_id = node_from_hash!({
      name: cypher_safe("#{hash['piFirstName']} #{hash['piLastName']}")
    }, 'Person', 'name')

    if hash['awardeeName'].present?
      org_id = node_from_hash!({
        name: cypher_safe(hash['awardeeName']),
        city: cypher_safe(hash['awardeeCity']),
        state: cypher_safe(hash['awardeeStateCode'])
      }, 'Org', 'name')
      @session.query(
        "MATCH (p:Person {madmp_id: '#{contributor_id}'}) \
         MATCH (o:Org {madmp_id: '#{org_id}'}) \
         MERGE (p)-[r:MEMBER_OF]->(o) \
         FOREACH(s IN CASE WHEN '#{@source}' IN r.sources THEN [] ELSE [1] END | SET r.sources = coalesce(r.sources, []) + '#{@source}')")
    end
    contributor_id
  end
end

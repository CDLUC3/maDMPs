require_relative './cypher_helper'

class Processor
  include CypherHelper

  def initialize(source, session)
    @source = cypher_safe(source)
    @session = session
  end

  # Add/Update the Project and attach Persons who have contributed
  # --------------------------------------------------------------
  def project_from_hash!(hash)
    props, rels = hash_to_props_and_rels(hash)
    project_id = node_from_hash!(hash.symbolize_keys, 'Project', 'title')

    hash.fetch(:markers, []).each do |marker|
      marker_id = marker_from_hash!(marker.symbolize_keys)
      @session.query(
        "MATCH (m:Marker {madmp_id: '#{marker_id}'}) \
         MATCH (p:Project {madmp_id: '#{project_id}'}) \
         MERGE (p)-[r:REFERENCES]->(m) \
         FOREACH(s IN CASE WHEN '#{@source}' IN r.sources THEN [] ELSE [1] END | SET r.sources = coalesce(r.sources, []) + '#{@source}')"
      )
    end

    hash.fetch(:documents, []).each do |document|
      doc_id = document_from_hash!(document.symbolize_keys)
      @session.query(
        "MATCH (d:Document {madmp_id: '#{doc_id}'}) \
         MATCH (p:Project {madmp_id: '#{project_id}'}) \
         MERGE (p)-[r:REFERENCES]->(d) \
         FOREACH(s IN CASE WHEN '#{@source}' IN r.sources THEN [] ELSE [1] END | SET r.sources = coalesce(r.sources, []) + '#{@source}')"
      )
    end

    hash.fetch(:contributors, []).each do |contributor|
      contrib_id = person_from_hash!(contributor.select{ |k,v| k != :role }.symbolize_keys)
      base_query = "MATCH (c:Person {madmp_id: '#{contrib_id}'}) \
                    MATCH (p:Project {madmp_id: '#{project_id}'}) \
                    MERGE (c)-[r:CONTRIBUTED_TO]->(p) "
      @session.query(!contributor.fetch(:role, nil).present? ? base_query :
        "#{base_query} \
         FOREACH(role IN CASE WHEN '#{cypher_safe(contributor[:role])}' IN r.roles THEN [] ELSE [1] END | SET r.roles = coalesce(r.roles, []) + '#{cypher_safe(contributor[:role])}') \
         FOREACH(s IN CASE WHEN '#{@source}' IN r.sources THEN [] ELSE [1] END | SET r.sources = coalesce(r.sources, []) + '#{@source}')")
    end

    hash.fetch(:awards, []).each do |award|
      award_id = award_from_hash!(award.symbolize_keys)
      @session.query(
        "MATCH (a:Award {madmp_id: '#{award_id}'}) \
         MATCH (p:Project {madmp_id: '#{project_id}'}) \
         MERGE (a)-[r:PRESENTED_TO]->(p) \
         FOREACH(s IN CASE WHEN '#{@source}' IN r.sources THEN [] ELSE [1] END | SET r.sources = coalesce(r.sources, []) + '#{@source}')"
      )
    end

    project_id
  end

  # Add/Update the Marker
  # --------------------------------------------------------------
  def marker_from_hash!(hash)
    node_from_hash!(hash, 'Marker', 'value')
  end

  # Add/Update the Document
  # --------------------------------------------------------------
  def document_from_hash!(hash)
    node_from_hash!(hash, 'Document', 'title')
  end

  # Add/Update the Person and attach Orgs they are a member of
  # --------------------------------------------------------------
  def person_from_hash!(hash)
    contributor_id = node_from_hash!(hash, 'Person', 'name')

    if hash[:org].present?
      org_id = org_from_hash!(hash[:org])
      @session.query(
        "MATCH (p:Person {madmp_id: '#{contributor_id}'}) \
         MATCH (o:Org {madmp_id: '#{org_id}'}) \
         MERGE (p)-[r:MEMBER_OF]->(o) \
         FOREACH(s IN CASE WHEN '#{@source}' IN r.sources THEN [] ELSE [1] END | SET r.sources = coalesce(r.sources, []) + '#{@source}')")
    end
    contributor_id
  end

  # Add/Update the Document
  # --------------------------------------------------------------
  def award_from_hash!(hash)
    award_id = node_from_hash!(hash, 'Award', 'title')

puts "****** Processing award: #{award_id}"

    if hash[:org].present?
      org_id = org_from_hash!(hash[:org])
      @session.query(
        "MATCH (a:Award {madmp_id: '#{award_id}'}) \
         MATCH (o:Org {madmp_id: '#{org_id}'}) \
         MERGE (o)-[r:FUNDED]->(a) \
         FOREACH(s IN CASE WHEN '#{@source}' IN r.sources THEN [] ELSE [1] END | SET r.sources = coalesce(r.sources, []) + '#{@source}')")
    end

    if hash[:offered_by].present?
      person_id = person_from_hash!(hash[:offered_by])
      @session.query(
        "MATCH (a:Award {madmp_id: '#{award_id}'}) \
         MATCH (p:Person {madmp_id: '#{person_id}'}) \
         MERGE (p)-[r:OFFERED]->(a) \
         FOREACH(s IN CASE WHEN '#{@source}' IN r.sources THEN [] ELSE [1] END | SET r.sources = coalesce(r.sources, []) + '#{@source}')")
    end
    award_id
  end

  # Add/Update the Org
  # --------------------------------------------------------------
  def org_from_hash!(hash)
    node_from_hash!(hash, 'Org', 'name')
  end
end

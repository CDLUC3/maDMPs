require 'mysql2'
require 'active_record'
require_relative './plan'
require_relative './role'
require_relative './user'
require_relative './org'
require_relative '../nosql_database/cypher_helper'
require_relative '../nosql_database/nosql_database'

class Dmptool
  include CypherHelper
  include Words

  def initialize
    ActiveRecord::Base.establish_connection(
      adapter: 'mysql2',
      database: 'dmp',
      username: 'root'
    )
    @source = 'dmptool'
    @session = NosqlDatabase.new.session
  end

  def process()
    puts "Searching for available projects ..."

    public_plans.each do |plan|
      hash = {
        source: @source,
        title: plan.title,
        identifiers: ["http://dmptool.org/plans/#{plan.id.to_s}"]
      }
      hash[:description] = plan.description if plan.description.present?
      hash[:identifiers] << plan.grant_number if plan.grant_number.present?
      hash[:identifiers] << plan.identifier if plan.identifier.present?

      project_id = node_from_hash!(hash, 'Project', 'title')
      org_id = nil

      plan.roles.each do |role|
        if role.access == 15
          add_contributor(role.user, 'Lead Principal Investigator', project_id)
          org_id = node_from_hash!({ name: cypher_safe(role.user.org.name)}, 'Org', 'name')
        elsif role.access == 14
          add_contributor(role.user, 'Co-Principal Investigator', project_id)
        end
      end

      if org_id.present?
        if plan.principal_investigator.present? || plan.principal_investigator_email.present? || plan.principal_investigator_identifier.present?
          pi = {
            name: (plan.principal_investigator ||= (plan.principal_investigator_email ||= plan.principal_investigator_identifier)),
            email: plan.principal_investigator_email,
            identifiers: [plan.principal_investigator_email, plan.principal_investigator_identifier]
          }
          pi_id = node_from_hash!(pi, 'Person', 'name')
          @session.query(
            "MATCH (o:Org {madmp_id: '#{org_id}'}) \
             MATCH (p:Person {madmp_id: '#{pi_id}'}) \
             MERGE (p)-[r:MEMBER_OF]->(o) \
             FOREACH(s IN CASE WHEN '#{@source}' IN r.sources THEN [] ELSE [1] END | SET r.sources = coalesce(r.sources, []) + '#{@source}')"
          )
          @session.query(
            "MATCH (o:Project {madmp_id: '#{project_id}'}) \
             MATCH (p:Person {madmp_id: '#{pi_id}'}) \
             MERGE (p)-[r:CONTRIBUTED_TO]->(o) \
             FOREACH(s IN CASE WHEN '#{@source}' IN r.sources THEN [] ELSE [1] END | SET r.sources = coalesce(r.sources, []) + '#{@source}')"
          )
        end
        if plan.data_contact.present? || plan.data_contact_email.present?
          dc = {
            name: plan.data_contact ||= plan.data_contact_email,
            email: plan.data_contact_email,
            identifiers: [plan.data_contact_email]
          }
          dc_id = node_from_hash!(dc, 'Person', 'name')
          @session.query(
            "MATCH (o:Org {madmp_id: '#{org_id}'}) \
             MATCH (p:Person {madmp_id: '#{dc_id}'}) \
             MERGE (p)-[r:MEMBER_OF]->(o) \
             FOREACH(s IN CASE WHEN '#{@source}' IN r.sources THEN [] ELSE [1] END | SET r.sources = coalesce(r.sources, []) + '#{@source}')"
          )
          @session.query(
            "MATCH (o:Project {madmp_id: '#{project_id}'}) \
             MATCH (p:Person {madmp_id: '#{dc_id}'}) \
             MERGE (p)-[r:CONTRIBUTED_TO]->(o) \
             FOREACH(s IN CASE WHEN '#{@source}' IN r.sources THEN [] ELSE [1] END | SET r.sources = coalesce(r.sources, []) + '#{@source}')"
          )
        end
      end

      doc = {
        title: "#{plan.title}",
        types: ["application/pdf", "PDF", "Data Management Plan"],
        identifiers: ["https://dmptool.org/plan_export/#{plan.id}.pdf"]
      }
      doc_id = node_from_hash!(doc, 'Document', 'title')
      @session.query(
        "MATCH (p:Project {madmp_id: '#{project_id}'}) \
         MATCH (d:Document {madmp_id: '#{doc_id}'}) \
         MERGE (d)-[r:REFERENCES]->(p) \
         FOREACH(s IN CASE WHEN '#{@source}' IN r.sources THEN [] ELSE [1] END | SET r.sources = coalesce(r.sources, []) + '#{@source}')"
      )
    end

    # Now scan the rest of the DMPTool for projects defined in the graph
    scannable_projects.each do |project|
      keywords = Words.cleanse(project[:title])

      lookup_dmp(keywords).each do |plan|
        update_graph_project(project, plan)
      end
    end
  end

  def scannable_projects
    # Only grab projects that are not already associated in some way with the DMPTool
    results = @session.query(
      "MATCH (p:Project)-[r]-() \
       WHERE NOT ANY(item IN r.sources WHERE item = '#{@source}') \
       RETURN p"
    )

    if results.any? && results.rows.length > 0 && results.rows.first.is_a?(Array)
      results.rows.map{ |row| row[0].props.select{ |k,v| k != :description } }
    else
      []
    end
  end

  def public_plans
    Plan.joins(roles: {user: :org}).includes(roles: {user: :org}).where("plans.visibility = 1")
  end

  def lookup_dmp(keywords)
    # TODO: Update to make this a safe query!
    Plan.includes(roles: {user: :org}).where(keywords.map{ |w| "LOWER(plans.title) LIKE '%#{w}%'" }.join(' AND '))
  end

  def update_graph_project(project, plan)
    if Words.match_percent(project[:title], plan.title) >= 0.9
      puts "    Project found in DMPTool: (graph: #{project[:madmp_id]}) '#{plan.title}'"
      add_identifier("http://dmptool.org/plans/#{plan.id.to_s}", project[:madmp_id])
      add_identifier(plan.grant_number.to_s, project[:madmp_id]) if plan.grant_number.present?

      plan.roles.each do |role|
        if role.access == 15
          add_contributor(role.user, 'Lead Principal Investigator', project[:madmp_id])
        elsif role.access == 14
          add_contributor(role.user, 'Co-Principal Investigator', project[:madmp_id])
        end
      end
    end
  end

  def add_contributor(user, role, project_id)
    user_id = node_from_hash!({ name: cypher_safe("#{user.firstname} #{user.surname}") }, 'Person', 'name')
    org_id = node_from_hash!({ name: cypher_safe(user.org.name)}, 'Org', 'name')
    @session.query(
      "MATCH (p:Person {madmp_id: '#{user_id}'}) \
       MATCH (o:Org {madmp_id: '#{org_id}'}) \
       MERGE (p)-[r:MEMBER_OF]->(o) \
       FOREACH(s IN CASE WHEN '#{@source}' IN r.sources THEN [] ELSE [1] END | SET r.sources = coalesce(r.sources, []) + '#{@source}')")

    @session.query(
      "MATCH (c:Person {madmp_id: '#{user_id}'}) \
       MATCH (p:Project {madmp_id: '#{project_id}'}) \
       MERGE (c)-[r:CONTRIBUTED_TO]->(p) \
       FOREACH(role IN CASE WHEN '#{cypher_safe(role)}' IN r.roles THEN [] ELSE [1] END | SET r.roles = coalesce(r.roles, []) + '#{cypher_safe(role)}') \
       FOREACH(s IN CASE WHEN '#{@source}' IN r.sources THEN [] ELSE [1] END | SET r.sources = coalesce(r.sources, []) + '#{@source}')")
  end

  def add_identifier(id, project_id)
    @session.query(
      "MATCH (p:Project {madmp_id: '#{cypher_safe(project_id)}'}) \
       MERGE (i:Identifier {value: '#{cypher_safe(id)}'})-[r:IDENTIFIES]->(p) \
       FOREACH(s IN CASE WHEN '#{@source}' IN r.sources THEN [] ELSE [1] END | SET r.sources = coalesce(r.sources, []) + '#{@source}')")
  end
end

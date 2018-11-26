require 'mysql2'
require 'active_record'
require_relative './plan'
require_relative './role'
require_relative './user'
require_relative './org'
require_relative './user_identifier'
require_relative './identifier_scheme'
require_relative '../../database/cypher_helper'
require_relative '../../database/nodes/project'
require_relative '../../database/nodes/person'
require_relative '../../database/nodes/org'
require_relative '../../database/nodes/document'

class Dmptool
  include Database::CypherHelper
  include Words

  def initialize(params)
    config = params.fetch(:mysql, {}).symbolize_keys

    ActiveRecord::Base.establish_connection(
      adapter: config.fetch(:adapter, 'mysql2'),
      host: config.fetch(:host, 'localhost'),
      port: config.fetch(:port, '3306'),
      database: config.fetch(:database, 'dmp'),
      username: config.fetch(:username, 'root'),
      password: config.fetch(:password, ''),
      #encoding: config.fetch(:encoding, 'utf8mb4'),
      #pool: config.fetch(:pool, 5)
    )
    @source = 'dmptool'
    @dmptool_url = "http://dmptool.org"
    @session = params.fetch(:session, nil)

    @orcid_scheme = IdentifierScheme.find_by(name: 'orcid')
  end

  def process()
    puts "Searching for public plans ..."

    public_plans.each do |plan|
      puts "  Processing #{plan.title}"
      add_dmptool_project_details_to_graph(plan)
    end

    # Now scan the rest of the DMPTool for projects defined in the graph
    puts ""
    puts "Scanning DMPTool for known projects ..."
    scannable_projects.each do |project|
      if project.present?
        keywords = Words.cleanse(project.title)

        lookup_dmp(keywords).each do |plan|
          puts "  Found match with #{plan.title}"
          update_graph_project(project, plan)
        end
      end
    end
  end

  def scannable_projects
    # Only grab projects that are not already associated in some way with the DMPTool
    results = @session.cypher_query(
      "MATCH (p:Project)-[r]-() \
       WHERE NOT ANY(item IN r.sources WHERE item = '#{@source}') \
       RETURN p"
    )
    if results.any? && results.rows.length > 0 && results.rows.first.is_a?(Array)
      results.rows.map{ |row| Database::Project.cypher_response_to_object(row[0].props) }
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
    if Words.match_percent(project[:title], plan.title) >= 0.8
      puts "    Project found in DMPTool: (graph: #{project.uuid}) '#{plan.title}'"
      add_dmptool_project_details_to_graph(plan)

      results = @session.cypher_query(
        "MATCH (a:Award)-[]-(p:Project {uuid: '#{cypher_safe(project.uuid)}'}) \
         RETURN MAX(a.updated_at)"
      )

      # Add the grant numbers from the graph to DMPTool db
      grants = plan.grant_number || ""
      if results.rows.any?
        ids = @session.cypher_query(
          "MATCH (i:Identifier)-[]-(a:Award {uuid: '#{results.rows.first[0].props[:uuid]}'}) \
           RETURN i"
        )
        if ids.rows.any?
          grants += ', ' unless grants.blank?
          grants += ids.rows.each.map{ |row| row[0].props[:value] }.join(', ')
        end
      end
      if grants != plan.grant_number
        puts "Adding award ids to DMPTool record for Plan #{plan.id} - #{plan.title}" if @session.debugging?
        plan.update_attributes(grant_number: grants)
      end
    end
  end

  def add_dmptool_project_details_to_graph(plan)
    hash = {
      session: @session,
      source: @source,
      title: plan.title,
      identifiers: ["#{@dmptool_url}/plans/#{plan.id.to_s}"]
    }
    #hash[:identifiers] << plan.grant_number if plan.grant_number.present?
    hash[:identifiers] << plan.identifier if plan.identifier.present?

    project = Database::Project.find_or_create(hash)
    puts "Saving (p:Project)" if @session.debugging?
    project.save(hash)
    org = nil

    plan.roles.each do |role|
      if role.access == 15
        add_contributor(role.user, 'Lead Principal Investigator', project)
        org = role.user.org
      elsif role.access == 14
        add_contributor(role.user, 'Co-Principal Investigator', project)
      end
    end

    if org.present?
      if plan.principal_investigator.present? || plan.principal_investigator_email.present? || plan.principal_investigator_identifier.present?
        pi = User.new(
          firstname: (plan.principal_investigator || plan.principal_investigator_email || plan.principal_investigator_identifier),
          email: plan.principal_investigator_email,
          org: org
        )
        if plan.principal_investigator_identifier.present?
          pi.user_identifiers << UserIdentifier.new(
            identifier: plan.principal_investigator_identifier,
            identifier_scheme: @orcid_scheme
          )
        end
        add_contributor(pi, 'Lead Principal Investigator', project)
      end

      if plan.data_contact.present? || plan.data_contact_email.present?
        dc = User.new(
          firstname: plan.data_contact || plan.data_contact_email,
          email: plan.data_contact_email,
          org: org
        )
        add_contributor(dc, 'Data Contact', project)
      end
    end

    doc_params = {
      session: @session,
      source: @source,
      title: "#{plan.title}",
      types: ["application/pdf", "PDF", "Data Management Plan"],
      identifiers: ["#{@dmptool_url}/plan_export/#{plan.id}.pdf"]
    }
    doc = Database::Document.find_or_create(doc_params)
    puts "Saving (d:Document)" if @session.debugging?
    doc.save(doc_params)

    puts "Saving (:Project)-[:PRODUCED]->(:Document)" if @session.debugging?
    @session.cypher_query(cypher_relate(project, doc, 'PRODUCED', { source: @source }))
  end

  def add_contributor(user, role, project)
    params = {
      session: @session,
      source: @source,
      name: "#{user.firstname} #{user.surname}",
      email: user.email,
      identifiers: [user.email, "#{@dmptool_url}/users/#{user.id}", get_user_orcid(user)]
    }
    contributor = Database::Person.find_or_create(params)
    puts "Saving (:Person)" if @session.debugging?
    contributor.save(params)

    org_params = {
      session: @session,
      source: @source,
      name: user.org.name,
      identifiers: [user.org.abbreviation, "#{@dmptool_url}/orgs/#{user.org.id}"]
    }
    org = Database::Org.find_or_create(org_params)
    puts "Saving (:Org)" if @session.debugging?
    org.save(org_params)

    puts "Saving (:Person)-[:AFFILIATED_WITH]->(:Org)" if @session.debugging?
    @session.cypher_query(cypher_relate(contributor, org, 'AFFILIATED_WITH', { source: @source }))

    puts "Saving (:Person)-[:CONTRIBUTES_TO]->(:Project)" if @session.debugging?
    @session.cypher_query(cypher_relate(contributor, project, 'CONTRIBUTES_TO', { source: @source, role: role }))

    org
  end

  def get_user_orcid(user)
    if @orcid_scheme.present?
      user.user_identifiers.where(identifier_scheme_id: @orcid_scheme.id)
    end
  end
end

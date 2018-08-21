require_relative './base_node'
require_relative './org'

module Database
  class Person < BaseNode
    attr_accessor :name, :email

    def save(**params)
      super(params)

      if params[:org].present?
        args = params[:org].merge({ session: params[:session], source: params[:source] })
        org = Database::Org.find_or_create(args)
        org.save(args)
        puts "Saving (:Person)-[:AFFILIATED_WITH]->(:Org)" if session.debugging?
        session.cypher_query(cypher_relate(self, org, 'AFFILIATED_WITH', { source: params[:source] }))
      end
    end
  end
end
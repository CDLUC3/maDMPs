require_relative './base_node'
require_relative './org'

module Database
  class Award < BaseNode
    attr_accessor :title, :amount, :date
    attr_reader :org

    def save(**params)
      super(params)

      if params[:org].present?
        args = params[:org].merge({ session: params[:session], source: params[:source] })
        org = Database::Org.find_or_create(args)
        org.save(args)
        puts "Saving (:Org)-[:FUNDED]->(:Award)" if session.debugging?
        session.cypher_query(cypher_relate(org, self, 'FUNDED', { source: params[:source] }))
      end
    end
  end
end
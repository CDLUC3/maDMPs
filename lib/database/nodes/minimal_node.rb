require_relative '../cypher_helper'

module Database
  class MinimalNode
    include Database::CypherHelper

    attr_reader :uuid, :created_at, :updated_at
    attr_accessor :value, :sources

    def initialize(**params)
      @uuid = params.fetch(:uuid, self.generate_uuid)
      @created_at = params.fetch(:created_at, Time.now.to_s)
      @updated_at = params.fetch(:updated_at, Time.now.to_s)
      @sources = params.fetch(:sources, [])
      @session = params.fetch(:session, nil)
      @value = params.fetch(:value, '')

      @sources = JSON.parse(@sources) unless @sources.is_a?(Array)
    end

    def save(**params)
      session = params.fetch(:session, nil)
      if session.present? && session.respond_to?(:cypher_query) && params[:source].present?
        @updated_at = Time.now.to_s
        @sources << params[:source] unless @sources.include?(params[:source])

        puts "Saving (:#{self.class_to_label})" if session.debugging?
        session.cypher_query(cypher_merge)
      end
    end

    def self.find_or_create(**params)
      if params[:session].present? && params[:source].present? && params[:value].present?
        result = params[:session].cypher_query(self.cypher_match(value: params[:value]))
        if result.present? && result.rows.any?
          rec = result.rows.first[0]
          if rec.present? && rec.is_a?(Neo4j::Core::Node) && !rec.props.empty?
            puts "Found - uuid: #{rec.props[:uuid]}" if params[:session].debugging?
            node = self.send(:new, rec.props)
          end
        else
          puts "No match found" if params[:session].debugging?
        end
        node = self.send(:new, params) unless node.present?
        node.sources << params[:source] unless node.sources.include?(params[:source])
        node
      end
    end
  end
end
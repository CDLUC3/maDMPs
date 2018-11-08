require_relative './type'
require_relative './identifier'
require_relative '../cypher_helper'
require_relative '../../helpers/words'

module Database
  class BaseNode
    include Words
    include Database::CypherHelper

    attr_reader :label
    attr_reader :uuid, :created_at, :updated_at, :sources, :identifiers, :types
    attr_accessor :params, :session

    def initialize(params)
      @session = params.fetch(:session, nil)
      @label = self.class.name.split(':').last

      props, rels = hash_to_props_and_rels(params)
      define_attrs(props)

      @uuid = self.generate_uuid unless @uuid.present?
      @created_at = Time.now.to_s unless @created_at.present?
      @sources = [] unless @sources.present?
      @sources = JSON.parse(@sources) unless @sources.is_a?(Array)

      @identifiers = [] unless @identifiers.present?
      @types = [] unless @types.present?
      @identifiers = JSON.parse(@identifiers) unless @identifiers.is_a?(Array)
      @types = JSON.parse(@types) unless @types.is_a?(Array)
    end

    def add_source(val)
      @sources << val unless @sources.include?(val)
    end
    def add_identifier(val)
      @identifiers << val if val.is_a?(Database::Identifier) && !@identifiers.include?(val)
    end
    def add_type(val)
      @types << val if val.is_a?(Database::Type) && !@types.include?(val)
    end

    def self.find(session, uuid)
      if session.present?
        cypher_response_to_object(session.cypher_query(self.cypher_match({ uuid: uuid })))
      end
    end

    def self.find_or_create(**params)
      if params[:session].present? && params[:source].present?
        identifiers = params.fetch(:identifiers, [])
        types = params.fetch(:types, [])

        puts "Searching for (:#{self.class_to_label})" if params[:session].debugging?
        node = cypher_response_to_object(self.fuzzy_match({
          source: params.fetch(:source, 'dmptool'),
          session: params.fetch(:session, nil),
          identifiers: identifiers,
          keywords: params.keys.include?(:title) ? { title: params[:title] } : { name: params.fetch(:name, '') }
        })) || self.send(:new, params)

        node.session = params[:session] unless node.session.present?

        # Attach any Identifiers to the instance
        identifiers.each do |id|
          puts "Searching for (:Identifier)" if params[:session].debugging?
          node.add_identifier(Database::Identifier.find_or_create(
            source: params[:source],
            session: params[:session],
            value: id
          ))
        end

        # Attach any Types to the instance
        types.each do |id|
          puts "Searching for (:Type)" if params[:session].debugging?
          node.add_type(Database::Type.find_or_create(
            source: params[:source],
            session: params[:session],
            value: id
          ))
        end
        node
      end
    end

    def self.all(session)
      if session.present?
        cypher_response_to_object(session.cypher_query(cypher_match))
      end
    end

    def save(**params)
      session = params.fetch(:session, nil)
      if session.present? && session.respond_to?(:cypher_query) && params[:source].present?
        props, rels = self.hash_to_props_and_rels(params)
        define_attrs(props)

        @updated_at = Time.now.to_s
        @sources << params[:source] unless @sources.include?(params[:source])

        puts "Saving (:#{self.class_to_label})" if session.debugging?
        session.cypher_query(cypher_merge)

        @identifiers.each do |identifier|
          identifier.save({ session: session, source: params[:source] })
          puts "Saving (:Identifier)-[:IDENTIFIES]->(:#{self.class_to_label})" if session.debugging?
          session.cypher_query(cypher_relate(identifier, self, 'IDENTIFIES', { source: params[:source] }))
        end

        @types.each do |type|
          type.save({ session: session, source: params[:source] })
          puts "Saving (:Type)-[:DEFINES]->(:#{self.class_to_label})" if session.debugging?
          session.cypher_query(cypher_relate(type, self, 'DEFINES', { source: params[:source] }))
        end
      end
    end

    def delete
      puts "Feature not yet implemented!"
    end

    protected
      def self.hash_to_props_and_rels(hash)
        props, rels = {}, {}
        hash.map{ |k, v| v.is_a?(Array) || v.is_a?(Hash) ? rels[k] = v : props[k] = v }
        return props, rels
      end
      def hash_to_props_and_rels(hash)
        self.class.send(:hash_to_props_and_rels, hash)
      end

      def define_attrs(hash)
        # Dynamically assign attributes (create the accessor if necessary)
        hash.each_pair do |k, v|
          unless [:session, :source, :created_at, :updated_at, :role].include?(k)
            if !instance_variables.include?("@#{k}".to_sym)
              if !self.respond_to?("#{k}=".to_sym)
                self.instance_eval { class << self; self end }.send(:attr_accessor, k.to_sym)
              end
              self.send("#{k}=".to_sym, v)
            end
          end
        end
      end

      def self.fuzzy_match(**params)
        matches = []
        source, session = params.fetch(:source, ''), params.fetch(:session, nil)
        if session.present? && session.respond_to?(:cypher_query) && source.present?
          params.fetch(:identifiers, []).each do |id|
            unless id.blank?
              # If the identifier is a URL or UUID then we can safely match without the context of the source
              # These identifiers can be considered high-quality
              if id.to_s.match?('^http(s)?://.*') ||
                 id.to_s.match?('([a-zA-Z0-9]{4,}\-){4,}') ||
                 id.to_s.match?('.*[@]{1}.*(\.[a-zA-Z]{2,3})')
                results = session.cypher_query(
                  "MATCH (:Identifier {value: '#{cypher_safe(id)}'})-[:IDENTIFIES]->(n:#{class_to_label}) \
                   RETURN (n)"
                )
              else
                # Otherwise consider the source along with the identifier
                results = session.cypher_query(
                  "MATCH (i:Identifier {value: '#{cypher_safe(id)}'})-[:IDENTIFIES]->(n:#{class_to_label}) \
                   WHERE i.sources in ['#{source}'] \
                   RETURN (n)")
              end
              matches << results.rows.first if results.rows.any?
            end
          end

          # No identifiers matched and keywords were provided
          keywords = params.fetch(:keywords, {})
          if matches.empty? && !keywords.empty?
            where_clause = ""
            params.fetch(:keywords, {}).each_pair do |k, v|
              if v.present?
                words = Words.cleanse(v.to_s)
                if words.length > 0
                  where_clause += " AND " unless where_clause.blank?
                  where_clause += "(#{words.map{ |w| "n.#{k} =~ '.*(?i)#{cypher_safe(w)}.*'" }.join(' AND ')})"
                end
              end
            end

            unless where_clause.blank?
              results = session.cypher_query("MATCH (n:#{self.class_to_label}) WHERE #{where_clause} RETURN (n)")
              matches << results.rows if results.rows.any?
            end
          end
        end

        unless matches.empty?
          best_match = matches.sort{ |a,b| a[0]<=>b[0] }.last
          if best_match.is_a?(Array)
            best_match = best_match[0] if best_match[0].is_a?(Array)
            puts "#{matches.any? ? "Found - uuid: #{best_match[0].props[:uuid]}" : 'No matches found.'}" if session.debugging?
            best_match[0]
          end
        else
          puts "no matches found." if session.debugging?
        end
      end
  end
end

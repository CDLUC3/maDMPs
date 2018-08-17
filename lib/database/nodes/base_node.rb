require_relative '../cypher_helper'

module Database
  class BaseNode
    include Database::CypherHelper

    attr_reader :label
    attr_reader :uuid, :created_at, :updated_at, :sources, :identifiers, :types
    attr_accessor :params

    def initialize(**params)
      @session = params.fetch(:session, nil)
      @label = self.class.name.split(':').last

      @uuid = params.fetch(:uuid, generate_uuid)
      @created_at = params.fetch(:created_at, Time.now.to_s)
      @updated_at = params.fetch(:updated_at, Time.now.to_s)
      @sources = params.fetch(:sources, [])
      @identifiers = params.fetch(:identifiers, [])
      @types = params.fetch(:types, [])

      # Dynamically assign incoming params (create the accessor if necessary)
      params.each_pair do |k, v|
        if !instance_variables.include?("@#{k}".to_sym)
          if !self.respond_to?("#{k}=".to_sym)
            self.instance_eval { class << self; self end }.send(:attr_accessor, k.to_sym)
          end
          self.send("#{k}=".to_sym, v)
        end
      end
    end

    def add_source(val)
      @sources << val unless @sources.include?(val)
    end
    def add_identifier(val)
      @identifiers << val unless @identifiers.include?(val)
    end
    def add_type(val)
      @types << val unless @types.include?(val)
    end

    def self.find(session, uuid)
      if session.present?
        cypher_response_to_object(session.cypher_query(self.cypher_match({ uuid: uuid })))
      end
    end

    def self.find_by(**params)
      if params[:session].present?
        cypher_response_to_object(params[:session].cypher_query(cypher_match(params)))
      end
    end

    def self.all(session)
      if session.present?
        cypher_response_to_object(session.cypher_query(cypher_match))
      end
    end

    def save
      @session.cypher_query(cypher_merge)
    end

    def delete
      puts "Feature not yet implemented!"
    end

    def serialize_attributes
      pairs = []
      instance_variables.each do |v|
        unless ['@label', '@session'].include?(v.to_s)
          att = v.to_s.gsub('@', '')
          pairs << "#{att}: '#{cypher_safe(self.send(att.to_sym))}'"
        end
      end
      "{#{pairs.join(', ')}}"
    end

    protected
      def generate_uuid
        SecureRandom.hex
      end

      def self.fuzzy_match(**params)

        search_fields = params.keys.select{ |k| ![:identifiers].include?(k) }

        query = " \
         MATCH (n:#{self.class_to_label} \
         WHERE (#{search_fields.map{ |k, v| "n.#{k} = '#{cypher_safe(v)}'" }.join(' AND ')}) \
        "

        # Search by identifiers
        unless ids.empty?
          ids.each do |id|
            query += " \
              MATCH (:Identifier {value: '#{cypher_safe(id)}'})-[:IDENTIFIES]->(n:#{label}) \
            "
            if id.to_s.match?('^http(s)?://.*')

            else
              # Otherwise consider the source along with the identifier
              results = @session.query(
                "MATCH (i:Identifier {value: '#{cypher_safe(id)}'})-[:IDENTIFIES]->(n:#{label}) \
                 WHERE i.sources in ['#{@source}'] RETURN (n)")
              matches << results.rows.first if results.any?
            end
          end
        end

        if matches.empty?
          # Look for a match by keyword
          words = Words.cleanse(keyword.to_s)
          query_stem = ("MATCH (n:#{label}) WHERE %{where_clause} RETURN (n)")
          where_clause = words.map{ |w| "n.#{property} =~ '.*(?i)#{cypher_safe(w)}.*'" }.join(' OR ')

          if where_clause.present?
            # Retrieve all of the nodes that contain parts of the value's words
            # For example if value = 'University of California - Berkeley' search
            # the graph for any nodes with a title containing University, California or
            # Berkeley.
            results = @session.query(query_stem % { where_clause: where_clause })

            if results.any?
              # Search through the results and attempt to find a match
              results.rows.each do |row|
                node = row.first
                probability = Words.match_percent(keyword, node.props[property.to_sym])
                matches << [probability, node.props[property.to_sym]] #unless probability < 0.75
              end
            end
          end

          best_match = matches.sort{ |a,b| a[0]<=>b[0] }.last
          best_match.respond_to?(:rows) ? (best_match.rows.empty? ? nil : best_match.rows[1][0]) : nil
        end
      end
  end
end

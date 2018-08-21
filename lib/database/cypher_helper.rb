module Database
  module CypherHelper
    def self.included(base)
      def base.generate_uuid
        SecureRandom.hex
      end

      def base.cypher_safe(string)
        string.to_s.squish.gsub("'", '"')
      end

      def base.class_to_label
        self.name.split(':').last
      end

      def base.hash_to_cypher(hash)
        pairs = []
        hash.each_pair{ |k,v| pairs << "#{k}: '#{cypher_safe(v)}'" }
        "{#{pairs.join(', ')}}"
      end

      def base.hash_to_where_clause(hash)
        pairs = []
        hash.each_pair{ |k,v| pairs << "n.#{k} = '#{cypher_safe(v)}'" }
        "{#{pairs.join(' AND ')}}"
      end

      def base.cypher_match(**params)
        if params.empty?
          "MATCH (n:#{self.class_to_label}) \
           RETURN (n) "
        else
          "MATCH (n:#{self.class_to_label} #{self.hash_to_cypher(params)}) \
           RETURN (n) "
        end
      end

      def base.cypher_response_to_object(response)
        if response.present? && response.is_a?(Neo4j::Core::Node) && !response.props.empty?
          self.send(:new, response.props)
        end
      end
    end

    # Instance methods that wrap class methods
    def generate_uuid
      self.class.generate_uuid
    end
    def class_to_label
      self.class.class_to_label
    end
    def cypher_safe(string)
      self.class.cypher_safe(string)
    end
    def class_to_label
      self.class.class_to_label
    end
    def hash_to_cypher(hash)
      self.class.hash_to_cypher(hash)
    end
    def cypher_response_to_object(response)
      self.class.cypher_response_to_object(response)
    end

    def serialize_attributes
      pairs = []
      instance_variables.each do |v|
        unless ['@label', '@session', '@identifiers', '@types'].include?(v.to_s)
          att = v.to_s.gsub('@', '')
          pairs << "#{att}: '#{cypher_safe(self.send(att.to_sym))}'"
        end
      end
      "{#{pairs.join(', ')}}"
    end

    def cypher_merge
      "MERGE (n:#{self.class_to_label.capitalize} {uuid: '#{@uuid}'}) \
       SET n += #{serialize_attributes} "
    end

    def cypher_delete
      "DELETE (n:#{self.class_to_label.capitalize} {uuid: '#{@uuid}'}) "
    end

    def cypher_relate(from, to, relationship_label, params)
      query = " \
       MATCH (a:#{from.class.class_to_label} {uuid: '#{from.uuid}'}) \
       MATCH (b:#{to.class.class_to_label} {uuid: '#{to.uuid}'}) \
       MERGE (a)-[r:#{relationship_label.upcase}]->(b) "

      params.each_pair do |k, v|
        key = k.to_s.pluralize
        query += " \
          FOREACH(item IN CASE WHEN '#{v}' IN r.#{key} THEN [] ELSE [1] END | SET r.#{key} = coalesce(r.#{key}, []) + '#{v}') "
     end
     query
    end
  end
end

module Database
  module CypherHelper
    def self.included(base)
      def base.cypher_safe(string)
        string.to_s.squish.gsub("'", '"')
      end

      def base.class_to_label
        self.class.name.split(':').last
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

      def base.cypher_identifier_match(**params)
        ids = params[:identifiers] || []

      end

      def base.cypher_response_to_object(response)
        if response.any?
          node = response.rows.first
          if node.present? && node.is_a?(Array) && !node[0].props.empty?
            self.send(:new, node[0].props)
          end
        end
      end
    end

    #fuzzy_search(label, unique_property, hash[unique_property.to_sym], hash[:identifiers])

    # Instance methods that wrap class methods
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

    def cypher_merge()
      "MERGE (n:#{@label.capitalize} {uuid: '#{@uuid}'}) \
       SET n += #{serialize_attributes} "
    end

    def cypher_delete
      "DELETE (n:#{@label.capitalize} {uuid: '#{@uuid}'}) "
    end

  end
end

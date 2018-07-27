class CypherHelper
  include Words

  def initialize(session)
    @session = session
  end

  def project_from_hash(hash)
    if hash.is_a?(Hash) && hash[:title].present?
      props, rels = hash_to_props_and_rels(hash)

      # See if the node exists
      selector = {title: props[:title]}

      # Do an exact match search first on the title. If not found do a fuzzy search
      node = @session.query("MATCH (n:Project #{hash_to_cypher(selector)}) RETURN n").rows.first
      node = fuzzy_search('Project', 'title', props[:title]) unless node.present?
      props = props.merge(node.props) if node.present?

      # If the node does not exist give it a unique identifier
      props[:madmp_id] = generate_madmps_id unless node.present?

      @session.query("MERGE (n:Project #{hash_to_cypher(props)}) RETURN n")
      identifiers = [props[:title]].merge(hash[:identifiers]).flatten.uniq
      identifier_query = "MATCH (p:Project {madmp_id: '#{props[:madmp_id]}'}) "
      identifiers.each do |id|
        identifier_query += "MERGE (:Identifier {value: '#{id.gsub(/\'/, "\'")}'})-[:IDENTIFIES]->(p) "
      end

      puts identifier_query

    end
  end

  def fuzzy_search(label, property, value)
    words = Words.cleanse(value)
    query_stem = ("MATCH (n:#{label}) WHERE %{where_clause} RETURN (n)")

    # Retrieve all of the nodes that contain parts of the value's words
    # For example if value = 'University of California - Berkeley' search
    # the graph for any nodes with a title containing University, California or
    # Berkeley.
    nodes = @session.query(query_stem % { where_clause: words.map{ |w| "n.#{property} =~ '.*(?i)#{w.gsub("'", "\'")}.*'" }.join(' OR ') })

    # Search through the results and attempt to find a match
    matches = []
    nodes.each do |row|
      probability = Words.match_percent(value, row[1].props[:title])
      matches << [probability, row[1]] #unless probability < 0.75
    end
    matches.sort{ |a,b| a[0]<=>b[0] }.last[1]
  end

  # Convert incoming JSON hash to separate Cypher property and relationship
  # arrays based on whether the entry is a JSON Array
  def hash_to_props_and_rels(hash)
    props, rels = {}, {}
    hash.map{ |k, v| v.is_a?(Array) ? rels[k] = v : props[k] = v }
    return props, rels
  end

  # Convert the Property hash to a Cypher query string
  # e.g. {:propA=>"ValueA",:propB=>"ValueB"} --> '{propA: "ValueA", propB: "ValueB"}'
  def hash_to_cypher(hash)
    pairs = []
    hash.each_pair{ |k,v| pairs << "#{k}: '#{v}'" }
    "{#{pairs.join(', ')}}"
  end

  # Add the madmps_id property to the hash if it doesn't exist
  def generate_madmps_id
    SecureRandom.hex
  end
end

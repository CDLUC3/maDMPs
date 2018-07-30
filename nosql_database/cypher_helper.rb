class CypherHelper
  include Words

  def initialize(source, session)
    @source = source
    @session = session
  end

  # Add/Update the Project and attach Persons who have contributed
  # --------------------------------------------------------------
  def project_from_hash!(hash)
    project_id = node_from_hash!(hash, 'Project', 'title')

    hash[:contributors].each do |contributor|
      contrib_id = person_from_hash!(contributor.select{ |k,v| k != :role })
      
      @session.query(
        "MATCH (p:Project {madmp_id: '#{project_id}'}) \
         MATCH (c:Person {madmp_id: '#{contrib_id}'}) \
         MERGE (c)-[r:CONTRIBUTED_TO]->(p) \
         FOREACH(role IN CASE WHEN '#{contributor[:role]}' IN r.roles THEN [] ELSE [1] END | SET r.roles = coalesce(r.roles, []) + '#{contributor[:role]}')")
    end
    project_id
  end

  # Add/Update the Person and attach Orgs they are a member of
  # --------------------------------------------------------------
  def person_from_hash!(hash)
    contributor_id = node_from_hash!(hash, 'Person', 'name')
    
    if hash[:org].present?
      org_id = org_from_hash!(hash[:org])
      @session.query(
        "MATCH (p:Person {madmp_id: '#{contributor_id}'}) \
         MATCH (o:Org {madmp_id: '#{org_id}'}) \
         MERGE (p)-[r:MEMBER_OF]->(o)")
    end
    contributor_id
  end
  
  # Add/Update the Org
  # --------------------------------------------------------------
  def org_from_hash!(hash)
    node_from_hash!(hash, 'Org', 'name')
  end
  
  # Generic method to Add/Update the specified label w/unique_property and attach any identifiers
  # --------------------------------------------------------------
  def node_from_hash!(hash, label, unique_property)
    if hash.is_a?(Hash) && hash[:name].present?
      props, rels = hash_to_props_and_rels(hash)
      selector = {"#{unique_property}": props[unique_property.to_sym]}
      ids = [props[unique_property.to_sym], hash[:identifiers]].flatten.uniq

      # Do an exact match search first on the title. If not found do a fuzzy search
      result = @session.query("MATCH (n:#{label} #{hash_to_cypher(selector)}) RETURN n")

puts "CLASS NAME: #{result.class.name}"
puts "ANY? #{result.any?}"
puts "HASHES --------------------"
puts result.hashes.inspect
puts "STRUCTS --------------------"
puts result.hashes.inspect

      node = result.rows.first if result.present?
      
      node = fuzzy_search(label, unique_property, hash[unique_property.to_sym], hash[:identifiers]) unless node.present?
      madmp_id = (node.present? ? (node.is_a?(Array) ? node[0].props[:madmp_id] : node.props[:madmp_id]) : generate_madmps_id)
      
      @session.query(
        "MERGE (n:#{label} {madmp_id: '#{madmp_id}'}) \
         SET n += #{hash_to_cypher(props)}")
      
      ids.each do |id|
        if id.present?
          @session.query(
            "MATCH (n:#{label} {madmp_id: '#{madmp_id}'}) \
             MERGE (i:Identifier {value: '#{id.gsub(/\'/, "\'")}'}) \
             MERGE (i)-[r:IDENTIFIES]->(o) \
             FOREACH(s IN CASE WHEN '#{@source}' IN r.sources THEN [] ELSE [1] END | SET r.sources = coalesce(r.sources, []) + '#{@source}')")
        end
      end
      madmp_id
    end
  end
  
  # Generic method to search for nodes based on a keyword or identifiers.
  # Function returns the most likely match based on:
  #   1) identifier match if the identifier is a URL
  #   2) identifier match if the source is also the same (e.g. value: '0123456789' for source: 'biocode')
  #   3) keyword matches exactly (e.g. title: 'Moorea Biocode Project')
  #   4) We were able to derive a > 2 character acronym and it had a match (e.g. 'UCB' for 'University of California - Berkeley' == 'UC Berkeley')
  #   5) A percentage, 75%, of the words in the keyword matched
  # --------------------------------------------------------------
  def fuzzy_search(label, property, keyword, identifiers)
    matches = []
    
    # Search by identifiers
    if identifiers.present? && identifiers.is_a?(Array)
      identifiers.each do |id|
        if id.to_s.match?('^http(s)?://.*')
          # If its a URL then we have a unique identifier!
          matches << @session.query("MATCH (:Identifier {value: '#{id}'})-[:IDENTIFIES]->(n:#{label}) RETURN (n)")
        else
          # Otherwise consider the source along with the identifier
          matches << @session.query(
            "MATCH (i:Identifier {value: '#{id}'})-[:IDENTIFIES]->(n:#{label}) \
             WHERE i.sources in ['#{@source}'] RETURN (n)")
        end
      end
    end
    
    if matches.empty?
      # Look for a match by keyword
      words = Words.cleanse(keyword)
      query_stem = ("MATCH (n:#{label}) WHERE %{where_clause} RETURN (n)")

      # Retrieve all of the nodes that contain parts of the value's words
      # For example if value = 'University of California - Berkeley' search
      # the graph for any nodes with a title containing University, California or
      # Berkeley.
      nodes = @session.query(query_stem % { where_clause: words.map{ |w| "n.#{property} =~ '.*(?i)#{w.gsub("'", "\'")}.*'" }.join(' OR ') })

      # Search through the results and attempt to find a match
      nodes.each do |row|
        probability = Words.match_percent(value, row[1].props[:title])
        matches << [probability, row[1]] #unless probability < 0.75
      end
    end

puts matches.class.name

    best_match = matches.sort{ |a,b| a[0]<=>b[0] }.last
    best_match.respond_to?(:rows) ? (best_match.rows.empty? ? nil : best_match.rows[1][0]) : nil
  end

  # Convert incoming JSON hash to separate Cypher property and relationship
  # arrays based on whether the entry is a JSON Array
  # --------------------------------------------------------------
  def hash_to_props_and_rels(hash)
    props, rels = {}, {}
    hash.map{ |k, v| v.is_a?(Array) || v.is_a?(Hash) ? rels[k] = v : props[k] = v }
    return props, rels
  end

  # Convert the Property hash to a Cypher query string
  # e.g. {:propA=>"ValueA",:propB=>"ValueB"} --> '{propA: "ValueA", propB: "ValueB"}'
  # --------------------------------------------------------------
  def hash_to_cypher(hash)
    pairs = []
    hash.each_pair{ |k,v| pairs << "#{k}: '#{v}'" }
    "{#{pairs.join(', ')}}"
  end

  # Get a UUID
  # --------------------------------------------------------------
  def generate_madmps_id
    SecureRandom.hex
  end
end

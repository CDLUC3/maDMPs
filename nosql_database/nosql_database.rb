require 'neo4j'
require 'neo4j/session_manager'

# Used example at: https://github.com/neo4j-examples/movies-ruby-neo4jrb

class NosqlDatabase
  def self.process(service, json)
    if json.is_a?(Hash)
      puts "  Loading #{service} metadata into the graph database."
      Neo4j::ActiveBase.on_establish_session do
        Neo4j::SessionManager.open_neo4j_session(:http, 'http://neo4j:madmps@localhost:7474')
      end
      session = Neo4j::ActiveBase.current_session
    
      json[:projects].each do |project|
        processNode(session, 'project', project)
      end
      
      session.query('MATCH (n) RETURN (n)').each do |node|
        puts node.inspect
      end
    end
  end
  
  def self.processNode(session, label, hash)
    props = {}
    rels = {}
    hash.keys.each do |k|
      if hash[k].is_a?(Array)
        rels[k] = hash[k]
      else
        props[k] = hash[k]
      end
    end
    
    # See if the node exists
    selector = props[:title].present? ? { title: props[:title] } : { name: props[:name] }
    node = session.query("MATCH (n:#{label.capitalize} #{hash_to_cypher(selector)}) RETURN n")

    # If the node does not exist give it a unique identifier
    props[:madmp_id] = SecureRandom.hex unless node.rows.present?
    session.query("MERGE (n:#{label.capitalize} #{hash_to_cypher(props)}) RETURN n")
  end
  
  def self.hash_to_cypher(hash)
    pairs = []
    hash.each_pair{ |k,v| pairs << "#{k}: '#{v}'" }
    "{#{pairs.join(', ')}}"
  end
end
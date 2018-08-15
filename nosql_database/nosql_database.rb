require 'neo4j'
#require 'neo4j/session_manager'
require 'neo4j/core/cypher_session/adaptors/bolt'
require_relative '../helpers/words'
require_relative './processor'

# Used example at: https://github.com/neo4j-examples/movies-ruby-neo4jrb
class NosqlDatabase
  attr_reader :session

  def initialize
    puts "  Establishing connection to Neo4j"
    #Neo4j::ActiveBase.on_establish_session do
      #Neo4j::SessionManager.open_neo4j_session(:http, 'http://neo4j:madmps@localhost:7687')
    #end
    #@session = Neo4j::ActiveBase.current_session
    @neo4j_adaptor = Neo4j::Core::CypherSession::Adaptors::Bolt.new('bolt://neo4j:madmps@localhost:7687')
    @session = Neo4j::Core::CypherSession.new(@neo4j_adaptor)
  end

  def process(service, json)
    if json.is_a?(Hash)
      puts "  Loading #{service} metadata into the graph database."
      json[:projects].each do |project|
        puts "    Processing - `#{project[:title]}`"
        project = Processor.new(service, @session).project_from_hash!(project)
      end
    end
  end
end

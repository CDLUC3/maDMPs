require 'neo4j'
require 'neo4j/session_manager'
require_relative '../helpers/words'
require_relative './processor'

# Used example at: https://github.com/neo4j-examples/movies-ruby-neo4jrb
class NosqlDatabase
  attr_reader :session

  def initialize
    puts "  Establishing connection to Neo4j"
    Neo4j::ActiveBase.on_establish_session do
      Neo4j::SessionManager.open_neo4j_session(:http, 'http://neo4j:madmps@localhost:11001')
    end
    @session = Neo4j::ActiveBase.current_session
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

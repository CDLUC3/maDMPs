require 'neo4j'
require 'neo4j/core/cypher_session/adaptors/bolt'
require 'neo4j/core/cypher_session/adaptors/http'

module Database

  class Session
    def initialize(**options)
      protocol = "#{options.fetch(:adapter, 'http')}"
      host = "#{options.fetch(:host, 'localhost')}:#{options.fetch(:port, '7474')}"
      credentials = "#{options.fetch(:username, 'neo4j')}:#{options.fetch(:password, 'neo4j')}"
      connection = "#{protocol}://#{credentials}@#{host}"

      case protocol.downcase
      when 'bolt'
        @adapter = Neo4j::Core::CypherSession::Adaptors::Bolt.new(connection)
      when 'http'
        @adapter = Neo4j::Core::CypherSession::Adaptors::HTTPS.new(connection)
      else
        @adapter = Neo4j::Core::CypherSession::Adaptors::HTTP.new(connection)
      end

      @debug_mode = options.fetch(:debug, false)

      establish_connection
    end

    def debugging?
      @debug_mode
    end

    def cypher_query(query)
      establish_connection unless Neo4j::ActiveBase.current_session.present?
      if @debug_mode
        puts "  #{query}"
        puts ''
      end

      # Do not run any queries that would update the DB if we are in debug mode!
      if !@debug_mode || (@debug_mode && (!query.include?('MERGE') && !query.include?('CREATE') &&
                                          !query.include?('SET') && !query.include?('DELETE')))
        Neo4j::ActiveBase.current_session.query(query)
      end
    end

    private
    def establish_connection
      Neo4j::ActiveBase.current_session = Neo4j::Core::CypherSession.new(@adapter)
    end
  end

end
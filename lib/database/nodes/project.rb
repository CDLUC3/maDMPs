require_relative './base_node'
require_relative './person'
require_relative './marker'
require_relative './document'
require_relative './award'

module Database
  class Project < BaseNode
    attr_accessor :title, :description, :api_scans
    attr_reader :contributors, :markers, :documents, :awards

    def initialize(params)
      super(params)
      @contributors = [] unless @contributors.present?
      @markers = [] unless @markers.present?
      @documents = [] unless @documents.present?
      @awards = [] unless @awards.present?

      @contributors = JSON.parse(@contributors) unless @contributors.is_a?(Array)
      @markers = JSON.parse(@markers) unless @markers.is_a?(Array)
      @documents = JSON.parse(@documents) unless @documents.is_a?(Array)
      @awards = JSON.parse(@awards) unless @awards.is_a?(Array)
    end

    def save(**params)
      super(params)

      params.fetch(:contributors, []).each do |contributor|
        args = contributor.merge({ session: params[:session], source: params[:source] })
        person = Database::Person.find_or_create(args)
        person.save(args)
        puts "Saving (:Person)-[:CONTRIBUTES_TO]->(:Project)" if session.debugging?
        session.cypher_query(cypher_relate(person, self, 'CONTRIBUTES_TO', { source: params[:source], role: contributor[:role] }))
      end

      params.fetch(:markers, []).each do |marker|
        args = marker.merge({ session: params[:session], source: params[:source] })
        obj = Database::Marker.find_or_create(args)
        obj.save(args)
        puts "Saving (:Project)-[:INVOLVES]->(:Marker)" if session.debugging?
        session.cypher_query(cypher_relate(self, obj, 'INVOLVES', { source: params[:source] }))
      end

      params.fetch(:documents, []).each do |document|
        args = document.merge({ session: params[:session], source: params[:source] })
        doc = Database::Document.find_or_create(args)
        doc.save(args)
        puts "Saving (:Project)-[:PRODUCED]->(:Document)" if session.debugging?
        session.cypher_query(cypher_relate(self, doc, 'PRODUCED', { source: params[:source] }))
      end

      params.fetch(:awards, []).each do |award|
        args = award.merge({ session: params[:session], source: params[:source] })
        award = Database::Award.find_or_create(args)
        award.save(args)
        puts "Saving (:Project)-[:RECEIVED]->(:Award)" if session.debugging?
        session.cypher_query(cypher_relate(self, award, 'RECEIVED', { source: params[:source] }))
      end
    end

    def add_contributor(val)
      @contributors << val if val.is_a?(Database::Person) && !@contributors.include?(val)
    end
    def remove_contributor(uuid)

    end

    def add_marker(marker)
      @markers << val if val.is_a?(Database::Marker) && !@markers.include?(val)
    end
    def remove_marker(uuid)

    end

    def add_document(document)
      @documents << val if val.is_a?(Database::Document) && !@documents.include?(val)
    end
    def remove_document(uuid)

    end

    def add_award(document)
      @awards << val if val.is_a?(Database::Award) && !@awards.include?(val)
    end
    def remove_award(uuid)

    end
  end
end
module Graph
  class Person
=begin
    include Neo4j::ActiveNode
    id_property :madmps_id
    property :name
    property :email

    has_many :out, :contributed_to, model_class: :Project, rel_class: 'Contributor'
    #has_many :in, :identifiers, model_class: :Identifier, :DESCRIBED

    #def self.from_hash

    #end
=end
  end
end

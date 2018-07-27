module Graph
  class Project
    include CypherHelper
    #include Neo4j::ActiveNode
    #id_property :madmps_id
    #property :title

    #has_many :in, :contributors, model_class: :Person, rel_class: 'Contributor'
    #has_many :in, :identifiers, model_class: :Identifier, :DESCRIBED
  end
end

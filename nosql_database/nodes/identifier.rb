module Graph
  class Identifier
    #include Neo4j::ActiveNode
    #id_property :madmps_id
    #property :value

    #has_many :out, :projects, model_class: :Project, :DESCRIBES
    #has_many :out, :persons, model_class: :Person, :DESCRIBES
  end
end

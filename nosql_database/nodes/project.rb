class Project
  include Neo4j::ActiveNode
  id_property :madmps_id
  property :title
  
  has_many :in, :contributors, model_class: :Person, rel_class: 'Contributor'
  
  def self.from_hash
    
  end
end

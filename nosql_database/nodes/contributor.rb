module Graph
  class Contributor
=begin
  include Neo4j::ActiveRel

  property :roles
  from_class 'Person'
  to_class 'Project'
  type :CONTRIBUTED_TO
=end
  end
end

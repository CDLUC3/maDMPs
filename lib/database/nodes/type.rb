module Database
  class Type
    include Neo4j::ActiveNode
    # Adds created_at and updated_at
    include Neo4j::Timestamps

    property :value
    validates :value, presence: true, uniqueness: true
  end
end
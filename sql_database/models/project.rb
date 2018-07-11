class Project < ActiveRecord::Base
  belongs_to :source
  has_many :identifiers, through: :project_identifiers
  has_many :project_identifiers

  def self.find_or_create_by_hash(hash)
    if hash.is_a?(Hash)
      # If the id was passed, get the Project otherwise search for it based on its identifiers
      if hash[:id].present?
        project = Project.find(hash[:id])
      elsif hash[:identifiers].present? && !hash[:identifiers].is_a?(Array)
        project = Project.includes(:identifiers).where(identifier: hash[:identifiers]).first
      end
      
      project = Project.find_by(title: hash[:title]) unless project.present?
      project = Project.create!(hash) unless project.present?
    else
      nil
    end
  end
  
  def self.create!(hash)
    params = hash.select{ |k, v| ![:awards, :contributors, :expeditions, :identifiers].include?(k) }
    project = Project.new(params)
    
    # Add any new identifiers or attach existing ones
    if hash[:identifiers].present? && hash[:identifiers].is_a?(Array)
      hash[:identifiers] = hash[:identifiers].map do |identifier|
        id = Identifier.find_or_create_by(identifier: identifier)
        if identifier.present?
          project.project_identifiers << ProjectIdentifier.new(identifier: id, source_id: hash[:source_id])
        end
      end
    end
    
    project.save!
    project
  end
end


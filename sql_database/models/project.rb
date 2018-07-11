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
      if project.present? 
        project.update_by_hash!(hash)
        project
      else 
        Project.create_by_hash!(hash)
      end
    else
      nil
    end
  end
  
  def self.create_by_hash!(hash)
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

  def update_by_hash!(hash)
    project.description = hash[:description] unless project.description.present?
    project.license = hash[:license] unless project.license.present?
    project.publication_date = hash[:publication_date] unless project.publication_date.present?
    project.language = hash[:language] unless project.language.present?
    
    # Add any new identifiers or attach existing ones
    if hash[:identifiers].present? && hash[:identifiers].is_a?(Array)
      hash[:identifiers] = hash[:identifiers].map do |identifier|
        id = Identifier.find_or_create_by(identifier: identifier)
        if identifier.present? && !ProjectIdentifier.find_by(identifier: id, project_id: self.id).present?
          project.project_identifiers << ProjectIdentifier.new(identifier: id, source_id: hash[:source_id])
        end
      end
    end
    
    project.update!
    project
  end
end


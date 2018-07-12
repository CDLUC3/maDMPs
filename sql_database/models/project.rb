class Project < ActiveRecord::Base
  belongs_to :source
  
  has_many :markers
  has_many :project_identifiers
  has_many :project_types

  has_many :identifiers, through: :project_identifiers
  has_many :types, through: :project_types
  
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
    params = hash.select{ |k, v| ![:awards, :contributors, :documents, :expeditions, :identifiers, :markers, :types].include?(k) }
    project = Project.new(params)
    
    # Add any new identifiers or attach existing ones
    project.project_identifiers = Array(hash.fetch(:identifiers, [])).map do |identifier|
      ProjectIdentifier.new(source_id: hash[:source_id], identifier_id: Identifier.find_or_create_by(value: identifier).id)
    end
    
    # Add any new types or attach existing ones
    project.project_types = Array(hash.fetch(:types, [])).map do |type|
      ProjectType.new(source_id: hash[:source_id], type_id: Type.find_or_create_by(value: type).id)
    end
    
    # Add any markers
    project.markers = Array(hash.fetch(:markers, [])).map do |marker|
      Marker.find_or_create_by(marker)
    end
    
    project.save!
    project
  end

  def update_by_hash!(hash)
    self.description = hash[:description] unless self.description.present?
    self.license = hash[:license] unless self.license.present?
    self.publication_date = hash[:publication_date] unless self.publication_date.present?
    self.language = hash[:language] unless self.language.present?
    
    # Add any new identifiers or attach existing ones
    Array(hash.fetch(:identifiers, [])).map do |identifier|
      obj = Identifier.find_or_create_by(value: identifier)
      if obj.present? && !ProjectIdentifier.find_by(source_id: hash[:source_id], identifier_id: obj.id, project_id: self.id).present?
        self.project_identifiers << ProjectIdentifier.new(source_id: hash[:source_id], identifier_id: obj.id)
      end
    end
    
    # Add any new types or attach existing ones
    Array(hash.fetch(:types, [])).map do |type|
      obj = Type.find_or_create_by(value: type)
      if obj.present? && !ProjectType.find_by(source_id: hash[:source_id], type_id: obj.id, project_id: self.id).present?
        self.project_types << ProjectType.new(source_id: hash[:source_id], type_id: obj.id)
      end
    end
    
    self.save!
  end
end


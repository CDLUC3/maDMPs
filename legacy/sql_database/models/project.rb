require 'json'

class Project < ActiveRecord::Base
  belongs_to :source

  has_many :api_scans
  has_many :markers
  has_many :project_identifiers
  has_many :project_types
  has_many :project_contributors
  has_many :project_awards
  has_many :project_stages
  has_many :project_documents

  has_many :identifiers, through: :project_identifiers
  has_many :types, through: :project_types
  has_many :contributors, through: :project_contributors
  has_many :awards, through: :project_awards
  has_many :stages, through: :project_stages
  has_many :documents, through: :project_documents

  validates :title, presence: true

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
    params = hash.select{ |k, v| ![:awards, :contributors, :documents, :stages, :identifiers, :markers, :types].include?(k) }

    if params[:title].present?
      project = Project.new(params)

      # Add any new identifiers or attach existing ones
      project.project_identifiers = Array(hash.fetch(:identifiers, [])).map do |identifier|
        ProjectIdentifier.new(source_id: hash[:source_id],
                              identifier_id: Identifier.find_or_create_by(value: identifier).id) if identifier.present?
      end

      # Add any new types or attach existing ones
      project.project_types = Array(hash.fetch(:types, [])).map do |type|
        ProjectType.new(source_id: hash[:source_id],
                        type_id: Type.find_or_create_by(value: type).id) if type.present?
      end

      # Add any markers
      markers = Array(hash.fetch(:markers, [])).map do |marker|
        marker[:source_id] = hash[:source_id]
        unless marker['httpStatusCode'].present?
          Marker.new(marker) if marker[:value].present?
        end
      end
      project.markers = markers.select{ |m| m.present? } || []

      # Add any new contributors or attach existing ones
      project.project_contributors = Array(hash.fetch(:contributors, [])).map do |contributor|
        contributor[:source_id] = hash[:source_id]
        obj = Contributor.find_or_create_by_hash(contributor)
        if obj.present?
          ProjectContributor.new(source_id: hash[:source_id], contributor_id: obj.id,
                                 type_id: Type.find_or_create_by(value: contributor.fetch(:role, 'Contributor')).id)
        end
      end

      # Add any new awards or attach existing ones
      project.project_awards = Array(hash.fetch(:awards, [])).map do |award|
        award[:source_id] = hash[:source_id]
        obj = Award.find_or_create_by_hash(award)
        if obj.present?
          ProjectAward.new(source_id: hash[:source_id], award_id: obj.id)
        end
      end

      # Add any new documents or attach existing ones
      project.project_documents = Array(hash.fetch(:documents, [])).map do |document|
        document[:source_id] = hash[:source_id]
        ProjectDocument.new(source_id: hash[:source_id],
                            document_id: Document.find_or_create_by_hash(document).id)
      end

      # Add any new stages or attach existing ones
      project.project_stages = Array(hash.fetch(:stages, [])).map do |stage|
        stage[:source_id] = hash[:source_id]
        ProjectStage.new(source_id: hash[:source_id],
                         stage_id: Stage.find_or_create_by_hash(stage).id)
      end
      project.save!
      project
    end
  end

  def update_by_hash!(hash)
    self.description = hash[:description] unless self.description.present?
    self.license = hash[:license] unless self.license.present?
    self.publication_date = hash[:publication_date] unless self.publication_date.present?
    self.language = hash[:language] unless self.language.present?

    # Add any new identifiers
    Array(hash.fetch(:identifiers, [])).map do |identifier|
      obj = Identifier.find_or_create_by(value: identifier)
      if obj.present? && !ProjectIdentifier.find_by(source_id: hash[:source_id], identifier_id: obj.id, project_id: self.id).present?
        self.project_identifiers << ProjectIdentifier.new(source_id: hash[:source_id], identifier_id: obj.id)
      end
    end

    # Add any new types
    Array(hash.fetch(:types, [])).map do |type|
      obj = Type.find_or_create_by(value: type)
      if obj.present? && !ProjectType.find_by(source_id: hash[:source_id], type_id: obj.id, project_id: self.id).present?
        self.project_types << ProjectType.new(source_id: hash[:source_id], type_id: obj.id)
      end
    end

    # Add any new contributors
    Array(hash.fetch(:contributors, [])).map do |contributor|
      contributor[:source_id] = hash[:source_id]
      obj = Contributor.find_or_create_by_hash(contributor)
      if obj.present? && !ProjectContributor.find_by(project_id: self.id, contributor_id: obj.id).present?
        self.project_contributors << ProjectContributor.new(
          source_id: hash[:source_id],
          type_id: Type.find_or_create_by(value: contributor.fetch(:role, 'Contributor')).id,
          contributor_id: obj.id)
      end
    end

    # Add any new awards
    Array(hash.fetch(:awards, [])).map do |award|
      award[:source_id] = hash[:source_id]
      obj = Award.find_or_create_by_hash(award)
      if obj.present? && !ProjectAward.find_by(project_id: self.id, award_id: obj.id).present?
        self.project_awards << ProjectAward.new(source_id: hash[:source_id], award_id: obj.id)
      end
    end

    # Add any new documents
    Array(hash.fetch(:documents, [])).map do |document|
      document[:source_id] = hash[:source_id]
      obj = Document.find_or_create_by_hash(document)
      if obj.present? && !ProjectDocument.find_by(project_id: self.id, document_id: obj.id).present?
        self.project_documents << ProjectDocument.new(source_id: hash[:source_id], document_id: obj.id)
      end
    end

    # Add any new stages
    Array(hash.fetch(:stages, [])).map do |stage|
      stage[:source_id] = hash[:source_id]
      obj = Stage.find_or_create_by_hash(stage)
      if obj.present? && !ProjectStage.find_by(project_id: self.id, stage_id: obj.id).present?
        self.project_stages << ProjectStage.new(source_id: hash[:source_id], stage_id: obj.id)
      end
    end
    self.save!
  end
end

class Stage < ActiveRecord::Base
  belongs_to :source

  has_many :stage_identifiers
  has_many :stage_types
  has_many :stage_contributors
  has_many :stage_documents

  has_many :identifiers, through: :stage_identifiers
  has_many :types, through: :stage_types
  has_many :contributors, through: :stage_contributors
  has_many :documents, through: :stage_documents

  validates :title, presence: true

  def self.find_or_create_by_hash(hash)
    if hash.is_a?(Hash)
      # If the id was passed, get the Project otherwise search for it based on its identifiers
      if hash[:id].present?
        stage = Stage.find(hash[:id])
      elsif hash[:identifiers].present? && !hash[:identifiers].is_a?(Array)
        stage = Stage.includes(:identifiers).where(identifier: hash[:identifiers]).first
      end
      stage = Stage.find_by(title: hash[:title]) unless stage.present?
      if stage.present?
        stage.update_by_hash!(hash)
        stage
      else
        Stage.create_by_hash!(hash)
      end
    else
      nil
    end
  end

  def self.create_by_hash!(hash)
    params = hash.select{ |k, v| ![:identifiers, :types, :documents, :contributors].include?(k) }

    if params[:title].present?
      stage = Stage.new(params)

      # Add any new identifiers or attach existing ones
      stage.stage_identifiers = Array(hash.fetch(:identifiers, [])).map do |identifier|
        StageIdentifier.new(source_id: hash[:source_id],
                            identifier_id: Identifier.find_or_create_by(value: identifier).id) if identifier.present?
      end

      # Add any new types or attach existing ones
      stage.stage_types = Array(hash.fetch(:types, [])).map do |type|
        StageType.new(source_id: hash[:source_id],
                      type_id: Type.find_or_create_by(value: type).id) if type.present?
      end

      # Add any new contributors or attach existing ones
      stage.stage_contributors = Array(hash.fetch(:contributors, [])).map do |contributor|
        contributor[:source_id] = hash[:source_id]
        obj = Contributor.find_or_create_by_hash(contributor)
        if obj.present?
          StageContributor.new(source_id: hash[:source_id],
                               type_id: Type.find_or_create_by(value: contributor.fetch(:role, 'Contributor')).id,
                               contributor_id: obj.id)
        end
      end

      # Add any new documents or attach existing ones
      stage.stage_documents = Array(hash.fetch(:documents, [])).map do |document|
        document[:source_id] = hash[:source_id]
        obj = Document.find_or_create_by_hash(document)
        if obj.present?
          StageDocument.new(source_id: hash[:source_id], document_id: obj.id)
        end
      end

      stage.save!
      stage
    end
  end

  def update_by_hash!(hash)
    # Add any new identifiers or attach existing ones
    Array(hash.fetch(:identifiers, [])).map do |identifier|
      obj = Identifier.find_or_create_by(value: identifier)
      if obj.present? && !StageIdentifier.find_by(source_id: hash[:source_id], identifier_id: obj.id, stage_id: self.id).present?
        self.stage_identifiers << StageIdentifier.new(source_id: hash[:source_id], identifier_id: obj.id)
      end
    end

    # Add any new types or attach existing ones
    Array(hash.fetch(:types, [])).map do |type|
      obj = Type.find_or_create_by(value: type)
      if obj.present? && !StageType.find_by(source_id: hash[:source_id], type_id: obj.id, stage_id: self.id).present?
        self.document_types << StageType.new(source_id: hash[:source_id], type_id: obj.id)
      end
    end

    # Add any new contributors
    Array(hash.fetch(:contributors, [])).map do |contributor|
      contributor[:source_id] = hash[:source_id]
      obj = Contributor.find_or_create_by_hash(contributor)
      if obj.present? && !StageContributor.find_by(stage_id: self.id, contributor_id: obj.id).present?
        self.stage_contributors << StageContributor.new(
          source_id: hash[:source_id],
          type_id: Type.find_or_create_by(value: contributor.fetch(:role, 'Contributor')).id,
          contributor_id: obj.id)
      end
    end

    # Add any new documents
    Array(hash.fetch(:documents, [])).map do |document|
      document[:source_id] = hash[:source_id]
      obj = Document.find_or_create_by_hash(document)
      if obj.present? && !StageDocument.find_by(stage_id: self.id, document_id: obj.id).present?
        self.stage_documents << StageDocument.new(source_id: hash[:source_id], document_id: obj.id)
      end
    end

    self.save!
  end
end

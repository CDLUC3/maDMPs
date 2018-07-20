class Document < ActiveRecord::Base
  belongs_to :source

  has_many :document_identifiers
  has_many :document_types
  has_many :project_documents
  has_many :stage_documents

  has_many :identifiers, through: :document_identifiers
  has_many :types, through: :document_types
  has_many :projects, through: :project_documents
  has_many :stages, through: :stage_documents

  validates :title, presence: true

  def self.find_or_create_by_hash(hash)
    if hash.is_a?(Hash)
      # If the id was passed, get the Project otherwise search for it based on its identifiers
      if hash[:id].present?
        doc = Document.find(hash[:id])
      elsif hash[:identifiers].present? && !hash[:identifiers].is_a?(Array)
        doc = Document.includes(:identifiers).where(identifier: hash[:identifiers]).first
      end

      if doc.present?
        doc.update_by_hash!(hash)
        doc
      else
        Document.create_by_hash!(hash)
      end
    else
      nil
    end
  end

  def self.create_by_hash!(hash)
    params = hash.select{ |k, v| ![:identifiers, :types].include?(k) }

    if params[:title].present?
      doc = Document.new(params)

      # Add any new identifiers or attach existing ones
      doc.document_identifiers = Array(hash.fetch(:identifiers, [])).map do |identifier|
        DocumentIdentifier.new(source_id: hash[:source_id],
                          identifier_id: Identifier.find_or_create_by(value: identifier).id) if identifier.present?
      end

      # Add any new types or attach existing ones
      doc.document_types = Array(hash.fetch(:types, [])).map do |type|
        DocumentType.new(source_id: hash[:source_id],
                    type_id: Type.find_or_create_by(value: type).id) if type.present?
      end
      doc.save!
      doc
    end
  end

  def update_by_hash!(hash)
    # Add any new identifiers or attach existing ones
    Array(hash.fetch(:identifiers, [])).map do |identifier|
      obj = Identifier.find_or_create_by(value: identifier)
      if obj.present? && !DocumentIdentifier.find_by(source_id: hash[:source_id], identifier_id: obj.id, document_id: self.id).present?
        self.document_identifiers << DocumentIdentifier.new(source_id: hash[:source_id], identifier_id: obj.id)
      end
    end

    # Add any new types or attach existing ones
    Array(hash.fetch(:types, [])).map do |type|
      obj = Type.find_or_create_by(value: type)
      if obj.present? && !DocumentType.find_by(source_id: hash[:source_id], type_id: obj.id, document_id: self.id).present?
        self.document_types << DocumentType.new(source_id: hash[:source_id], type_id: obj.id)
      end
    end

    self.save!
  end
end

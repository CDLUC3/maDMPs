class Org < ActiveRecord::Base
  belongs_to :source
  has_many :org_identifiers
  has_many :org_types
  has_many :org_contributors

  has_many :identifiers, through: :org_identifiers
  has_many :types, through: :org_types
  has_many :contributors, through: :org_contributors

  validates :name, presence: true

  def self.find_or_create_by_hash(hash)
    if hash.is_a?(Hash)
      # If the id was passed, get the Project otherwise search for it based on its identifiers
      if hash[:id].present?
        org = Org.find(hash[:id])
      elsif hash[:identifiers].present? && !hash[:identifiers].is_a?(Array)
        org = Org.includes(:identifiers).where(identifier: hash[:identifiers]).first
      end
      org = Org.find_by(name: hash[:name]) unless org.present?
      if org.present?
        org.update_by_hash!(hash)
        org
      else
        Org.create_by_hash!(hash)
      end
    else
      nil
    end
  end

  def self.create_by_hash!(hash)
    params = hash.select{ |k, v| ![:awards, :identifiers, :types].include?(k) }

    if params[:name].present?
      org = Org.new(params)

      # Add any new identifiers or attach existing ones
      org.org_identifiers = Array(hash.fetch(:identifiers, [])).map do |identifier|
        OrgIdentifier.new(source_id: hash[:source_id],
                          identifier_id: Identifier.find_or_create_by(value: identifier).id) if identifier.present?
      end

      # Add any new types or attach existing ones
      org.org_types = Array(hash.fetch(:types, [])).map do |type|
        OrgType.new(source_id: hash[:source_id],
                    type_id: Type.find_or_create_by(value: type).id) if type.present?
      end
      org.save!
      org
    end
  end

  def update_by_hash!(hash)
    self.name = hash[:name] unless self.name.present?

    # Add any new identifiers or attach existing ones
    Array(hash.fetch(:identifiers, [])).map do |identifier|
      obj = Identifier.find_or_create_by(value: identifier)
      if obj.present? && !OrgIdentifier.find_by(source_id: hash[:source_id], identifier_id: obj.id, org_id: self.id).present?
        self.org_identifiers << OrgIdentifier.new(source_id: hash[:source_id], identifier_id: obj.id)
      end
    end

    # Add any new types or attach existing ones
    Array(hash.fetch(:types, [])).map do |type|
      obj = Type.find_or_create_by(value: type)
      if obj.present? && !OrgType.find_by(source_id: hash[:source_id], type_id: obj.id, org_id: self.id).present?
        self.org_types << OrgType.new(source_id: hash[:source_id], type_id: obj.id)
      end
    end

    self.save!
  end
end

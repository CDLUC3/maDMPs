class Project < ActiveRecord::Base
  belongs_to :source

  has_many :contributor_orgs
  has_many :contributor_identifiers
  has_many :contributor_projects

  has_many :identifiers, through: :contributor_identifiers
  has_many :orgs, through: :contributor_orgs
  has_many :projects, through: :contributor_projects

  def self.find_or_create_by_hash(hash)
    if hash.is_a?(Hash)
      # If the id was passed, get the Project otherwise search for it based on its identifiers
      if hash[:id].present?
        contributor = Contributor.find(hash[:id])
      elsif hash[:identifiers].present? && !hash[:identifiers].is_a?(Array)
        contributor = Contributor.includes(:identifiers).where(identifier: hash[:identifiers]).first
      end

      contributor = Contributor.find_by(email: hash[:email]) unless contributor.present? || !hash[:email].present?
      if contributor.present?
        contributor.update_by_hash!(hash)
        contributor
      else
        Contributor.create_by_hash!(hash)
      end
    else
      nil
    end
  end

  def self.create_by_hash!(hash)
    params = hash.select{ |k, v| ![:awards, :identifiers, :types].include?(k) }
    contributor = Contributor.new(params)

    # Add any new identifiers or attach existing ones
    contributor.contributor_identifiers = Array(hash.fetch(:identifiers, [])).map do |identifier|
      ContributorIdentifier.new(source_id: hash[:source_id], identifier_id: Identifier.find_or_create_by(value: identifier).id)
    end
    # Add any new identifiers or attach existing ones
    contributor.contributor_identifiers = Array(hash.fetch(:identifiers, [])).map do |identifier|
      ContributorIdentifier.new(source_id: hash[:source_id], identifier_id: Identifier.find_or_create_by(value: identifier).id)
    end
    # Add any new org or attach existing ones
    if hash[:org].present?
      hash[:org][:source_id] = hash[:source_id]
      contributor.contributor_orgs << OrgContributor.new(source_id: hash[:source_id],
                            org_id: Org.find_or_create_by_hash(hash[:org]).id)
    end
    contributor.save!
    contributor
  end

  def update_by_hash!(hash)
    self.name = hash[:name] unless self.name.present?
    self.email = hash[:email] unless self.email.present?

    # Add any new identifiers or attach existing ones
    Array(hash.fetch(:identifiers, [])).map do |identifier|
      obj = Identifier.find_or_create_by(value: identifier)
      if obj.present? && !ContributorIdentifier.find_by(source_id: hash[:source_id], identifier_id: obj.id, contributor_id: self.id).present?
        self.contributor_identifiers << ContributorIdentifier.new(source_id: hash[:source_id], identifier_id: obj.id)
      end
    end
    # Add any new org or attach existing ones
    if hash[:org].present?
      hash[:org][:source_id] = hash[:source_id]
      obj = Org.find_or_create_by_hash(hash[:org])
      if obj.present? && !OrgContributor.find_by(source_id: hash[:source_id], org_id: obj.id, contributor_id: self.id).present?
        self.contributor_orgs << OrgContributor.new(source_id: hash[:source_id], org_id: obj.id)
      end
    end
    self.save!
  end
end

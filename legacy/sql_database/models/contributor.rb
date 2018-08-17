class Contributor < ActiveRecord::Base
  belongs_to :source

  has_many :project_contributors
  has_many :contributor_identifiers
  has_many :org_contributors

  has_many :orgs, through: :org_contributors
  has_many :identifiers, through: :contributor_identifiers
  has_many :projects, through: :project_contributors

  def self.fuzzy_find(contributors, hash)
    matches = contributors.select{ |c| !c.identifiers.select{ |i| Words.match?(hash[:name], i.value) }.empty? }.first
    matches = contributors.select{ |c| Words.match?(hash[:name], c.name) }.first unless matches.present?
    if matches.present?
      matches
    else
      Contributor.new(hash)
    end
  end

  def self.find_or_create_by_hash(hash)
    if hash.is_a?(Hash)
      # If the id was passed, get the Project otherwise search for it based on its identifiers
      if hash[:id].present?
        contributor = Contributor.find(hash[:id])
      elsif hash[:identifiers].present? && !hash[:identifiers].is_a?(Array)
        contributor = Contributor.includes(:identifiers).where(identifier: hash[:identifiers]).first
      end

      contributor = Contributor.find_by('name = ? OR email = ?', hash[:name], hash[:email]) unless contributor.present?
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
    params = hash.select{ |k, v| ![:org, :role, :identifiers].include?(k) }

    if hash[:name].present? || hash[:email].present?
      contributor = Contributor.new(params)

      # Add any new identifiers or attach existing ones
      contributor.contributor_identifiers = Array(hash.fetch(:identifiers, [])).map do |identifier|
        ContributorIdentifier.new(source_id: hash[:source_id],
                                  identifier_id: Identifier.find_or_create_by(value: identifier).id) if identifier.present?
      end

      # If there is an email add that as an identifier
      if hash[:email].present?
        contributor.contributor_identifiers << ContributorIdentifier.new(source_id: hash[:source_id],
                                  identifier_id: Identifier.find_or_create_by(value: hash[:email]).id)
      end

      # Add the Org if applicable
      if hash[:org].present?
        hash[:org][:source_id] = hash[:source_id]
        org = Org.find_or_create_by_hash(hash[:org])
        if org.present?
          contributor.org_contributors << OrgContributor.new(source_id: hash[:source_id], org_id: org.id)
        end
      end
      contributor.save!
      contributor
    end
  end

  def update_by_hash!(hash)
    self.name = hash[:name] unless self.name.present?
    self.email = hash[:email] unless self.email.present?

    # Add any new identifiers
    Array(hash.fetch(:identifiers, [])).map do |identifier|
      obj = Identifier.find_or_create_by(value: identifier)
      if obj.present? && !ContributorIdentifier.find_by(source_id: hash[:source_id], identifier_id: obj.id, contributor_id: self.id).present?
        self.contributor_identifiers << ContributorIdentifier.new(source_id: hash[:source_id], identifier_id: obj.id)
      end
    end

    # Add the email to the identifiers list if its not already there
    if hash[:email].present?
      obj = Identifier.find_or_create_by(value: hash[:email])
      if obj.present? && !ContributorIdentifier.find_by(source_id: hash[:source_id], identifier_id: obj.id, contributor_id: self.id).present?
        self.contributor_identifiers << ContributorIdentifier.new(source_id: hash[:source_id],
                                  identifier_id: Identifier.find_or_create_by(value: hash[:email]).id)
      end
    end

    # Add the Org if applicable
    if hash[:org].present?
      hash[:org][:source_id] = hash[:source_id]
      org = Org.find_or_create_by_hash(hash[:org])
      if org.present? && !self.orgs.include?(org)
        OrgContributor.new(source_id: hash[:source_id], org_id: org.id, contributor_id: self.id, )
      end
    end
    self.save!
  end
end

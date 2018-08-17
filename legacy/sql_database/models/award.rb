class Award < ActiveRecord::Base
  belongs_to :source

  has_many :award_identifiers
  has_many :award_types
  has_many :award_contributors
  has_many :project_awards
  has_many :org_awards

  has_many :identifiers, through: :award_identifiers
  has_many :types, through: :award_types
  has_many :projects, through: :project_awards
  has_many :grantors, through: :award_contributors, source: :contributor
  has_many :granting_agencies, through: :org_awards, source: :org

  validates :title, presence: true

  def self.find_or_create_by_hash(hash)
    if hash.is_a?(Hash)
      # If the id was passed, get the Project otherwise search for it based on its identifiers
      if hash[:id].present?
        award = Award.find(hash[:id])
      elsif hash[:identifiers].present? && !hash[:identifiers].is_a?(Array)
        award = Award.includes(:identifiers).where(identifier: hash[:identifiers]).first
      end

      award = Award.find_by(title: hash[:title]) unless award.present?
      if award.present?
        award.update_by_hash!(hash)
        award
      else
        Award.create_by_hash!(hash)
      end
    else
      nil
    end
  end

  def self.create_by_hash!(hash)
    params = hash.select{ |k, v| ![:org, :offered_by, :identifiers, :types].include?(k) }

    if params[:title].present?
      award = Award.new(params)

      # Add any new identifiers or attach existing ones
      award.award_identifiers = Array(hash.fetch(:identifiers, [])).map do |identifier|
        AwardIdentifier.new(source_id: hash[:source_id],
                            identifier_id: Identifier.find_or_create_by(value: identifier).id) if identifier.present?
      end

      # Add any new types or attach existing ones
      award.award_types = Array(hash.fetch(:types, [])).map do |type|
        AwardType.new(source_id: hash[:source_id],
                        type_id: Type.find_or_create_by(value: type).id) if type.present?
      end

      # Add the Grantor if applicable
      if hash[:offered_by].present?
        hash[:offered_by][:source_id] = hash[:source_id]
        contributor = Contributor.find_or_create_by_hash(hash[:offered_by])
        if contributor.present?
          award.award_contributors << AwardContributor.new(
            source_id: hash[:source_id], contributor_id: contributor.id,
            type_id: Type.find_or_create_by(value: hash[:offered_by].fetch(:role, 'Program Manager')).id)
        end
      end

      # Add the Granting Agency if applicable
      if hash[:org].present?
        hash[:org][:source_id] = hash[:source_id]
        org = Org.find_or_create_by_hash(hash[:org])
        if org.present?
          award.org_awards << OrgAward.new(source_id: hash[:source_id], org_id: org.id)
        end
      end
      award.save!
      award
    end
  end

  def update_by_hash!(hash)
    self.description = hash[:description] unless self.description.present?
    self.title = hash[:title] unless self.title.present?
    self.amount = hash[:amount] unless self.amount.present?

    # Add any new identifiers
    Array(hash.fetch(:identifiers, [])).map do |identifier|
      obj = Identifier.find_or_create_by(value: identifier)
      if obj.present? && !AwardIdentifier.find_by(source_id: hash[:source_id], identifier_id: obj.id, award_id: self.id).present?
        self.award_identifiers << AwardIdentifier.new(source_id: hash[:source_id], identifier_id: obj.id)
      end
    end

    # Add any new types
    Array(hash.fetch(:types, [])).map do |type|
      obj = Type.find_or_create_by(value: type)
      if obj.present? && !AwardType.find_by(source_id: hash[:source_id], type_id: obj.id, award_id: self.id).present?
        self.award_types << AwardType.new(source_id: hash[:source_id], type_id: obj.id)
      end
    end

    # Add the Grantor if applicable
    if hash[:offered_by].present?
      hash[:offered_by][:source_id] = hash[:source_id]
      obj = Contributor.find_or_create_by_hash(hash[:offered_by])
      if obj.present? && !self.grantors.include?(obj)
        AwardContributor.new(source_id: hash[:source_id],
                  type_id: Type.find_or_create_by(value: hash[:offered_by].fetch(:role, 'Program Manager')).id,
                  contributor_id: obj.id, award_id: self.id, )
      end
    end

    # Add the Granting Agency if applicable
    if hash[:org].present?
      hash[:org][:source_id] = hash[:source_id]
      org = Org.find_or_create_by_hash(hash[:org])
      if org.present? && !self.granting_agencies.include?(org)
        OrgAward.new(source_id: hash[:source_id], org_id: org.id, award_id: self.id, )
      end
    end

    self.save!
  end
end

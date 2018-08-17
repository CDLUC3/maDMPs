class ContributorIdentifier < ActiveRecord::Base
  belongs_to :source
  belongs_to :contributor
  belongs_to :identifier
end

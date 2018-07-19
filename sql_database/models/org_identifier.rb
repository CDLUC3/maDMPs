class OrgIdentifier < ActiveRecord::Base
  belongs_to :source
  belongs_to :org
  belongs_to :identifier
end

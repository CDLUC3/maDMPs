class OrgContributor < ActiveRecord::Base
  belongs_to :org
  belongs_to :contributor
end

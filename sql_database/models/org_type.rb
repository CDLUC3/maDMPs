class OrgType < ActiveRecord::Base
  belongs_to :source
  belongs_to :org
  belongs_to :type
end

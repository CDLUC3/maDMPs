class OrgAward < ActiveRecord::Base
  belongs_to :org
  belongs_to :award
end

class StageContributor < ActiveRecord::Base
  belongs_to :source
  belongs_to :stage
  belongs_to :contributor
end

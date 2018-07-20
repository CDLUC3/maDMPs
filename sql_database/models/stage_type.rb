class StageType < ActiveRecord::Base
  belongs_to :source
  belongs_to :stage
  belongs_to :type
end

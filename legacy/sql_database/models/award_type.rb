class AwardType < ActiveRecord::Base
  belongs_to :source
  belongs_to :award
  belongs_to :type
end

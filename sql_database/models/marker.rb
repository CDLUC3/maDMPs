class Marker < ActiveRecord::Base
  belongs_to :project
  validates :value, presence: true
end

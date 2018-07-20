class Type < ActiveRecord::Base
  validates :value, presence: true
end

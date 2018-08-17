class Identifier < ActiveRecord::Base
  validates :value, presence: true
end

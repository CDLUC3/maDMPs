class User < ActiveRecord::Base
  belongs_to :org
  has_many :roles
  has_many :plans, through: :roles
  has_many :user_identifiers
end
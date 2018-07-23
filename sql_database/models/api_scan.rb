class ApiScan < ActiveRecord::Base
  belongs_to :source
  belongs_to :project
end

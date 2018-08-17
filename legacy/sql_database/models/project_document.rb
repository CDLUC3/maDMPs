class ProjectDocument < ActiveRecord::Base
  belongs_to :source
  belongs_to :project
  belongs_to :document
end

class ProjectStage < ActiveRecord::Base
  belongs_to :source
  belongs_to :project
  belongs_to :stage
end

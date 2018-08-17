class ProjectAward < ActiveRecord::Base
  belongs_to :project
  belongs_to :award
end

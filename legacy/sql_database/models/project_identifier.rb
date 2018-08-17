class ProjectIdentifier < ActiveRecord::Base
  belongs_to :source
  belongs_to :project
  belongs_to :identifier
end
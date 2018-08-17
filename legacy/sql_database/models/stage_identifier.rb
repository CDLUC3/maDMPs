class StageIdentifier < ActiveRecord::Base
  belongs_to :source
  belongs_to :stage
  belongs_to :identifier
end

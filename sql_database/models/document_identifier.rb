class DocumentIdentifier < ActiveRecord::Base
  belongs_to :source
  belongs_to :document
  belongs_to :identifier
end

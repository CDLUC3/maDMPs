class DocumentType < ActiveRecord::Base
  belongs_to :source
  belongs_to :document
  belongs_to :type
end

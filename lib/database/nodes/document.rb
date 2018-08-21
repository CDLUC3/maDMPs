require_relative './base_node'

module Database
  class Document < BaseNode
    attr_accessor :title
  end
end
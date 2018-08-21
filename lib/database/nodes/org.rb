require_relative './base_node'

module Database
  class Org < BaseNode
    attr_accessor :name, :website, :city, :state
  end
end
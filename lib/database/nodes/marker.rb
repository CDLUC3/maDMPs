require_relative './base_node'

module Database
  class Marker < BaseNode
    attr_accessor :value, :uri, :description
  end
end
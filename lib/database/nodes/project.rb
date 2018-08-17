require_relative './base_node'

module Database
  class Project < BaseNode
    attr_accessor :title, :description, :api_scans

  end
end
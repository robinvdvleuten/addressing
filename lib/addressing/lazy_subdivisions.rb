# frozen_string_literal: true

module Addressing
  # The children of a subdivision, loaded on first access.
  #
  # Behaves like the hash that Subdivision.all returns for the same parents.
  class LazySubdivisions
    extend Forwardable
    include Enumerable

    def_delegators :subdivisions, :each, :size, :keys, :values, :key?, :include?, :member?, :[], :fetch, :any?, :empty?, :select, :filter, :reject

    def initialize(parents)
      @parents = parents
    end

    private

    def subdivisions
      @subdivisions ||= Subdivision.all(@parents)
    end
  end
end

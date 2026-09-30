# frozen_string_literal: true

module Addressing
  # The children of a subdivision, loaded on first access.
  #
  # Behaves like the hash that Subdivision.all returns for the same parents.
  class LazySubdivisions
    extend Forwardable
    include Enumerable

    def_delegators :subdivisions, :each, :size, :keys, :values, :key?, :include?, :member?, :[], :fetch, :select, :filter, :reject

    def initialize(parents)
      @parents = parents
    end

    # Checks for children without building them.
    def empty?
      @subdivisions ? @subdivisions.empty? : Subdivision.list(@parents).empty?
    end

    def any?(*args, &block)
      return subdivisions.any?(*args, &block) if block || args.any?

      !empty?
    end

    private

    def subdivisions
      @subdivisions ||= Subdivision.all(@parents)
    end
  end
end

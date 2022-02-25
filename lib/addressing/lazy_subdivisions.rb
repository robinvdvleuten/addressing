# frozen_string_literal: true

module Addressing
  class LazySubdivisions
    def initialize(parents)
      @parents = parents
      @subdivisions = {}
      @initialized = false
    end

    def [](key)
      do_initialize unless @initialized
      @subdivisions[key]
    end

    def any?
      do_initialize unless @initialized
      @subdivisions.any?
    end

    def empty?
      do_initialize unless @initialized
      @subdivisions.empty?
    end

    private

    def do_initialize
      @initialized = true
      @subdivisions = Subdivision.all(@parents)
    end
  end
end

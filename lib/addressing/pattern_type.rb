# frozen_string_literal: true

module Addressing
  # Enumerates available pattern types.
  #
  # Determines whether regexes should match an entire string, or just a
  # part of it. Used for postal code validation.
  class PatternType < Enum
    FULL = "full"
    START = "start"

    # Gets the default value.
    def self.default
      # Most subdivisions define only partial patterns.
      START
    end
  end
end

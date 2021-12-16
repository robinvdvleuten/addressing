# frozen_string_literal: true

require "addressing/enum"

module Addressing
  # Enumerates available dependent locality types.
  class DependentLocalityType < Enum
    DISTRICT = "district"
    NEIGHBORHOOD = "neighborhood"
    VILLAGE_TOWNSHIP = "village_township"
    SUBURB = "suburb"
    TOWNLAND = "townland"

    # Gets the default value.
    def self.default
      SUBURB
    end
  end
end

# frozen_string_literal: true

module Addressing
  # Enumerates available locality types.
  class LocalityType < Enum
    CITY = "city"
    DISTRICT = "district"
    POST_TOWN = "post_town"
    SUBURB = "suburb"

    # Gets the default value.
    def self.default
      CITY
    end
  end
end

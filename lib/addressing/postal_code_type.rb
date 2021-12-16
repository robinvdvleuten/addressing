# frozen_string_literal: true

require "addressing/enum"

module Addressing
  # Enumerates available postal code types.
  class PostalCodeType < Enum
    EIR = "eircode"
    PIN = "pin"
    POSTAL = "postal"
    ZIP = "zip"

    # Gets the default value.
    def self.default
      POSTAL
    end
  end
end

# frozen_string_literal: true

require "addressing/enum"

module Addressing
  # Enumerates available administrative area types.
  class AdministrativeAreaType < Enum
    AREA = "area"
    CANTON = "canton"
    COUNTY = "county"
    DEPARTMENT = "department"
    DISTRICT = "district"
    DO_SI = "do_si"
    EMIRATE = "emirate"
    ISLAND = "island"
    OBLAST = "oblast"
    PARISH = "parish"
    PREFECTURE = "prefecture"
    PROVINCE = "province"
    STATE = "state"

    # Gets the default value.
    def self.default
      PROVINCE
    end
  end
end

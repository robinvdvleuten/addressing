# frozen_string_literal: true

require "addressing/enum"

module Addressing
  # Enumerates available address fields.
  class AddressField < Enum
    # The values match the address property names.
    ADMINISTRATIVE_AREA = "administrative_area"
    LOCALITY = "locality"
    DEPENDENT_LOCALITY = "dependent_locality"
    POSTAL_CODE = "postal_code"
    SORTING_CODE = "sorting_code"
    ADDRESS_LINE1 = "address_line1"
    ADDRESS_LINE2 = "address_line2"
    ORGANIZATION = "organization"
    GIVEN_NAME = "given_name"
    ADDITIONAL_NAME = "additional_name"
    FAMILY_NAME = "family_name"
  end
end

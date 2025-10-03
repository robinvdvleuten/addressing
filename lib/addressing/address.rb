# frozen_string_literal: true

module Addressing
  class Address
    FIELDS = %i[
      country_code administrative_area locality dependent_locality
      postal_code sorting_code address_line1 address_line2 address_line3
      organization given_name additional_name family_name locale
    ].freeze

    attr_reader(*FIELDS)

    def initialize(country_code: "", administrative_area: "", locality: "", dependent_locality: "", postal_code: "", sorting_code: "", address_line1: "", address_line2: "", address_line3: "", organization: "", given_name: "", additional_name: "", family_name: "", locale: "und")
      @country_code = country_code
      @administrative_area = administrative_area
      @locality = locality
      @dependent_locality = dependent_locality
      @postal_code = postal_code
      @sorting_code = sorting_code
      @address_line1 = address_line1
      @address_line2 = address_line2
      @address_line3 = address_line3
      @organization = organization
      @given_name = given_name
      @additional_name = additional_name
      @family_name = family_name
      @locale = locale
    end

    # Define with_* methods for all fields
    FIELDS.each do |field|
      define_method("with_#{field}") do |value|
        address = clone
        address.send("#{field}=", value)
        address
      end
    end

    protected

    attr_writer(*FIELDS)
  end
end

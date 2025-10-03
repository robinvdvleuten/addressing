# frozen_string_literal: true

module Addressing
  # Represents a postal address with attributes for country, administrative areas,
  # postal code, address lines, and recipient information.
  #
  # Address objects are immutable - use the +with_*+ methods to create modified copies.
  #
  # @example Creating an address
  #   address = Addressing::Address.new(
  #     country_code: "US",
  #     administrative_area: "CA",
  #     locality: "Mountain View",
  #     postal_code: "94043",
  #     address_line1: "1600 Amphitheatre Parkway"
  #   )
  #
  # @example Modifying an address
  #   updated = address.with_postal_code("94044")
  class Address
    FIELDS = %i[
      country_code administrative_area locality dependent_locality
      postal_code sorting_code address_line1 address_line2 address_line3
      organization given_name additional_name family_name locale
    ].freeze

    attr_reader(*FIELDS)

    # Creates a new Address instance.
    #
    # @param country_code [String] ISO 3166-1 alpha-2 country code
    # @param administrative_area [String] Top-level administrative subdivision (state, province, etc.)
    # @param locality [String] City or locality
    # @param dependent_locality [String] Dependent locality (neighborhood, suburb, district, etc.)
    # @param postal_code [String] Postal code
    # @param sorting_code [String] Sorting code (used in some countries)
    # @param address_line1 [String] First line of the street address
    # @param address_line2 [String] Second line of the street address
    # @param address_line3 [String] Third line of the street address
    # @param organization [String] Organization name
    # @param given_name [String] Given name (first name)
    # @param additional_name [String] Additional name (middle name, patronymic)
    # @param family_name [String] Family name (last name)
    # @param locale [String] Locale code for the address
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

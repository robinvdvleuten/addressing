# frozen_string_literal: true

module Addressing
  # Provides address format information for countries.
  #
  # Address formats define which fields are used, their order, requirements,
  # and formatting rules for postal addresses in different countries.
  #
  # @example Get address format for Brazil
  #   format = Addressing::AddressFormat.get('BR')
  #   format.used_fields        # => ["given_name", "family_name", ...]
  #   format.required_fields    # => ["address_line1", "locality", ...]
  #   format.subdivision_fields # => ["administrative_area", "locality"]
  class AddressFormat
    # The subdivision fields, ordered from the top level down.
    SUBDIVISION_FIELDS = [
      AddressField::ADMINISTRATIVE_AREA,
      AddressField::LOCALITY,
      AddressField::DEPENDENT_LOCALITY
    ].freeze

    # The defaults for every address format, including the fallback for
    # countries without a definition.
    GENERIC_DEFINITION = {
      format: "%given_name %family_name\n%organization\n%address_line1\n%address_line2\n%address_line3\n%locality",
      required_fields: [
        "address_line1", "locality"
      ].freeze,
      uppercase_fields: [
        "locality"
      ].freeze,
      subdivision_fields: [].freeze,
      administrative_area_type: "province",
      locality_type: "city",
      dependent_locality_type: "suburb",
      postal_code_type: "postal"
    }.freeze
    private_constant :GENERIC_DEFINITION

    class << self
      # Gets the address format for the provided country code.
      #
      # @param country_code [String] ISO 3166-1 alpha-2 country code
      # @return [AddressFormat] Address format instance
      def get(country_code)
        country_code = country_code.upcase
        # Unknown country codes often come from user input, so they are not cached.
        address_formats.fetch(country_code) { new(process_definition(country_code: country_code)) }
      end

      def all
        address_formats.dup
      end

      private

      # Gets the address formats by country code.
      #
      # All are built when the data is loaded, so that every call returns
      # the same instance for a country.
      def address_formats
        Addressing.data_source.fetch("address_formats") do |definitions|
          definitions.to_h do |country_code, definition|
            definition = definition.transform_keys(&:to_sym)
            definition[:default_values] = definition[:default_values].transform_keys(&:to_sym) if definition[:default_values]

            [country_code, new(process_definition(definition))]
          end
        end
      end

      def process_definition(definition)
        # Merge-in defaults.
        definition = GENERIC_DEFINITION.merge(definition)

        # Always require the given name and family name.
        definition[:required_fields] = definition[:required_fields] | [AddressField::GIVEN_NAME, AddressField::FAMILY_NAME]

        # The address formats are shared, so callers must not be able to
        # change their field lists.
        [:required_fields, :uppercase_fields, :subdivision_fields].each do |key|
          definition[key] = definition[key].dup.freeze
        end

        definition
      end
    end

    attr_reader :country_code, :locale, :format, :local_format, :required_fields, :uppercase_fields, :default_values, :administrative_area_type, :locality_type, :dependent_locality_type, :postal_code_type, :postal_code_pattern, :postal_code_prefix

    # The subdivision fields for which there is predefined subdivision data.
    #
    # This is more precise than #used_subdivision_fields, which returns all
    # subdivision fields used by the format regardless of whether data exists.
    #
    # @return [Array<String>] e.g. ["administrative_area", "locality"]
    attr_reader :subdivision_fields

    # The number of subdivision fields with predefined data used by the format.
    #
    # @deprecated Use #subdivision_fields instead.
    # @return [Integer]
    def subdivision_depth
      (subdivision_fields & used_subdivision_fields).size
    end

    def initialize(definition = {})
      # Validate the presence of required properties.
      [:country_code, :format].each do |required_property|
        if definition[required_property].nil?
          raise ArgumentError, "Missing required property #{required_property}."
        end
      end

      # Add defaults for properties that are allowed to be empty.
      definition = {
        locale: nil,
        local_format: nil,
        required_fields: [],
        uppercase_fields: [],
        default_values: {},
        postal_code_pattern: nil,
        postal_code_prefix: nil
      }.merge(definition)

      # Backwards compatibility: derive the subdivision fields from a depth.
      definition[:subdivision_fields] ||= SUBDIVISION_FIELDS.first(definition[:subdivision_depth] || 0)

      AddressField.assert_all_exist(definition[:required_fields])
      AddressField.assert_all_exist(definition[:uppercase_fields])
      AddressField.assert_all_exist(definition[:default_values].keys)
      AddressField.assert_all_exist(definition[:subdivision_fields])

      @country_code = definition[:country_code]
      @locale = definition[:locale]
      @format = definition[:format]
      @local_format = definition[:local_format]
      @required_fields = definition[:required_fields]
      @uppercase_fields = definition[:uppercase_fields]
      @default_values = definition[:default_values]
      @subdivision_fields = definition[:subdivision_fields]

      # A type is only set when the format uses its field.
      {
        administrative_area_type: [AddressField::ADMINISTRATIVE_AREA, AdministrativeAreaType],
        locality_type: [AddressField::LOCALITY, LocalityType],
        dependent_locality_type: [AddressField::DEPENDENT_LOCALITY, DependentLocalityType],
        postal_code_type: [AddressField::POSTAL_CODE, PostalCodeType]
      }.each do |key, (field, type)|
        next unless definition[key] && used_fields.include?(field)

        type.assert_exists(definition[key])
        instance_variable_set(:"@#{key}", definition[key])
      end

      if used_fields.include?(AddressField::POSTAL_CODE)
        @postal_code_pattern = definition[:postal_code_pattern]
        @postal_code_prefix = definition[:postal_code_prefix]
      end
    end

    # Gets the list of used fields.
    def used_fields
      @used_fields ||= AddressField.all.values.select { |field| @format.include?("%#{field}") }
    end

    # Gets the list of used subdivision fields.
    #
    # Note that a country might use a subdivision field without having
    # predefined subdivisions for it, see #subdivision_fields.
    def used_subdivision_fields
      SUBDIVISION_FIELDS & used_fields
    end
  end
end

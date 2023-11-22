# frozen_string_literal: true

module Addressing
  class AddressFormat
    class << self
      # The instantiated address formats, keyed by country code.
      @@address_formats = {}

      def get(country_code)
        country_code = country_code.upcase

        unless @@address_formats.key?(country_code)
          definition = process_definition(definitions[country_code] || {country_code: country_code})
          @@address_formats[country_code] = new(definition)
        end

        @@address_formats[country_code]
      end

      def all
        definitions.map do |country_code, definition|
          definition = process_definition(definition)
          [country_code, new(definition)]
        end.to_h
      end

      private

      def definitions
        @@definitions ||= Marshal.load(File.read(File.expand_path("../../../data/address_formats.dump", __FILE__).to_s))
      end

      def process_definition(definition)
        # Merge-in defaults.
        definition = generic_definition.merge(definition)

        # Always require the given name and family name.
        definition[:required_fields] << AddressField::GIVEN_NAME
        definition[:required_fields] << AddressField::FAMILY_NAME
        definition
      end

      def generic_definition
        {
          format: "%given_name %family_name\n%organization\n%address_line1\n%address_line2\n\address_line3\n%locality",
          required_fields: [
            "address_line1", "locality"
          ],
          uppercase_fields: [
            "locality"
          ],
          administrative_area_type: "province",
          locality_type: "city",
          dependent_locality_type: "suburb",
          postal_code_type: "postal",
          subdivision_depth: 0
        }
      end
    end

    attr_reader :country_code, :locale, :format, :local_format, :required_fields, :uppercase_fields, :administrative_area_type, :locality_type, :dependent_locality_type, :postal_code_type, :postal_code_pattern, :postal_code_prefix, :subdivision_depth

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
        postal_code_pattern: nil,
        postal_code_prefix: nil,
        subdivision_depth: 0
      }.merge(definition)

      AddressField.assert_all_exist(definition[:required_fields])
      AddressField.assert_all_exist(definition[:uppercase_fields])

      @country_code = definition[:country_code]
      @locale = definition[:locale]
      @format = definition[:format]
      @local_format = definition[:local_format]
      @required_fields = definition[:required_fields]
      @uppercase_fields = definition[:uppercase_fields]
      @subdivision_depth = definition[:subdivision_depth]

      if used_fields.include?(AddressField::ADMINISTRATIVE_AREA)
        if definition[:administrative_area_type]
          AdministrativeAreaType.assert_exists(definition[:administrative_area_type])
          @administrative_area_type = definition[:administrative_area_type]
        end
      end

      if used_fields.include?(AddressField::LOCALITY)
        if definition[:locality_type]
          LocalityType.assert_exists(definition[:locality_type])
          @locality_type = definition[:locality_type]
        end
      end

      if used_fields.include?(AddressField::DEPENDENT_LOCALITY)
        if definition[:dependent_locality_type]
          DependentLocalityType.assert_exists(definition[:dependent_locality_type])
          @dependent_locality_type = definition[:dependent_locality_type]
        end
      end

      if used_fields.include?(AddressField::POSTAL_CODE)
        if definition[:postal_code_type]
          PostalCodeType.assert_exists(definition[:postal_code_type])
          @postal_code_type = definition[:postal_code_type]
        end

        @postal_code_pattern = definition[:postal_code_pattern]
        @postal_code_prefix = definition[:postal_code_prefix]
      end
    end

    # Gets the list of used fields.
    def used_fields
      @used_fields ||= AddressField.all.filter_map do |key, value|
        value if @format.include?("%" + value)
      end
    end

    # Gets the list of used subdivision fields.
    def used_subdivision_fields
      fields = [
        AddressField::ADMINISTRATIVE_AREA,
        AddressField::LOCALITY,
        AddressField::DEPENDENT_LOCALITY
      ]

      # Remove fields not used by the format.
      fields & used_fields
    end
  end

  class AddressFormatHelper
    class << self
      # Gets the required fields.
      #
      # Applies field overrides to the required fields
      # specified by the address format.
      def required_fields(address_format, field_overrides)
        required_fields = address_format.required_fields
        required_fields -= field_overrides.optional_fields
        required_fields -= field_overrides.hidden_fields

        if field_overrides.required_fields
          required_fields += field_overrides.required_fields
          required_fields = required_fields.uniq
        end

        required_fields
      end
    end
  end
end

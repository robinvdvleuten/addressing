# frozen_string_literal: true

module Addressing
  # Validates an address against the address format of its country.
  #
  # @example
  #   address = Addressing::Address.new(country_code: "US", administrative_area: "XX")
  #   Addressing::AddressValidator.validate(address)
  #   # => [#<data Addressing::FieldViolation field=:address_line1, kind=:blank>, ...]
  class AddressValidator
    # Matches a value that holds nothing but whitespace, Unicode included.
    BLANK_PATTERN = /\A[[:space:]]*\z/
    private_constant :BLANK_PATTERN

    private_class_method :new

    class << self
      # Returns the field violations of the address.
      #
      # The rules, in the order in which their violations are reported:
      #
      # 1. Every required field is present. The field overrides make fields
      #    optional, hidden or required.
      # 2. Every field that the format does not use, or that is hidden, is blank.
      # 3. The subdivision levels match the predefined subdivisions, from the
      #    administrative area down. A hidden level ends the check.
      # 4. The postal code matches the whole pattern, ignoring case. The pattern
      #    comes from the last subdivision in the subdivision chain that has
      #    one, and otherwise from the address format.
      #
      # An address without a country code gives no field violations. Issue #58
      # tracks whether that should change.
      #
      # @param address [Address] The address to validate
      # @param field_overrides [FieldOverrides] Overrides of the fields of the address format
      # @param verify_postal_code [Boolean] Whether to check the postal code against its pattern
      # @return [Array<FieldViolation>] The field violations, empty when the address is valid
      def validate(address, field_overrides: FieldOverrides.new({}), verify_postal_code: true)
        return [] if blank?(address.country_code)

        address_format = AddressFormat.get(address.country_code)
        violations = []

        required_fields(address_format, field_overrides).each do |field|
          violations << violation(field, :blank) if blank?(address.send(field))
        end

        used_fields = address_format.used_fields - field_overrides.hidden_fields

        (AddressField.all.values - used_fields).each do |field|
          violations << violation(field, :present) unless blank?(address.send(field))
        end

        subdivision_fields = address_format.subdivision_fields
        # A hidden level is not validated, and neither are the levels below it.
        subdivision_values = subdivision_fields.map { |field| address.send(field) unless field_overrides.hidden_fields.include?(field) }
        chain = Subdivision.chain(address_format.country_code, subdivision_values)

        violations << violation(subdivision_fields[chain.unmatched_level], :invalid) if chain.unmatched_level

        if verify_postal_code && used_fields.include?(AddressField::POSTAL_CODE) && !valid_postal_code?(address.postal_code, chain.subdivisions, address_format)
          violations << violation(AddressField::POSTAL_CODE, :invalid)
        end

        violations
      end

      private

      def violation(field, kind)
        FieldViolation.new(field: field.to_sym, kind: kind)
      end

      # Whether the postal code matches the pattern of the last subdivision in
      # the chain that has one, or else the pattern of the address format.
      def valid_postal_code?(postal_code, subdivisions, address_format)
        # Nothing to validate.
        return true if blank?(postal_code)

        pattern = subdivisions.inject(address_format.postal_code_pattern) do |pattern, subdivision|
          blank?(subdivision.postal_code_pattern) ? pattern : subdivision.postal_code_pattern
        end
        return true unless pattern

        # The pattern must match the provided value completely.
        match = postal_code.match(Regexp.new(pattern, "i"))
        !match.nil? && match[0] == postal_code
      end

      # Applies the field overrides to the required fields of the address format.
      def required_fields(address_format, field_overrides)
        required_fields = address_format.required_fields - field_overrides.optional_fields - field_overrides.hidden_fields
        (required_fields + field_overrides.required_fields).uniq
      end

      # Whether the value is blank. Follows ActiveSupport's blank?, and uses it
      # when it is loaded.
      def blank?(value)
        return value.blank? if value.respond_to?(:blank?)

        case value
        when String then blank_string?(value)
        when nil, false then true
        else value.respond_to?(:empty?) && value.empty?
        end
      end

      def blank_string?(value)
        BLANK_PATTERN.match?(value)
      rescue Encoding::CompatibilityError
        # The value has an encoding that is not compatible with ASCII.
        Regexp.new(BLANK_PATTERN.source.encode(value.encoding), BLANK_PATTERN.options | Regexp::FIXEDENCODING).match?(value)
      end
    end
  end
end

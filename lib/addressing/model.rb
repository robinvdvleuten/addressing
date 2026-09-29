# frozen_string_literal: true

module Addressing
  module Model
    def validates_address_format(
      fields: Address::FIELDS, field_overrides: nil, verify_postal_code: true, **options
    )
      fields = Array(fields)
      field_overrides ||= FieldOverrides.new({})

      options[:if] ||= -> { fields.any? { |f| changes.key?(f.to_s) } } unless options[:unless]

      class_eval do
        validate :verify_address_format, **options

        define_method :verify_address_format do
          values = fields.each_with_object({}) { |f, v| v[f] = send(f) if respond_to?(f) }
          address = Address.new(**values)

          return unless address.country_code.present?

          address_format = AddressFormat.get(address.country_code)

          # Validate the presence of required fields.
          AddressFormatHelper.required_fields(address_format, field_overrides).each do |required_field|
            next unless address.send(required_field).blank?

            errors.add(required_field, "should not be blank")
          end

          used_fields = address_format.used_fields - field_overrides.hidden_fields

          # Validate the absence of unused fields.
          unused_fields = AddressField.all.values - used_fields
          unused_fields.each do |unused_field|
            next if address.send(unused_field).blank?

            errors.add(unused_field, "should be blank")
          end

          # Validate subdivisions.
          subdivisions = verify_subdivisions(address, address_format, field_overrides)

          # Validate postal code.
          verify_postal_code(address.postal_code, subdivisions, address_format) if used_fields.include?(AddressField::POSTAL_CODE) && verify_postal_code
        end

        define_method :verify_subdivisions do |address, address_format, field_overrides|
          subdivision_fields = address_format.subdivision_fields
          # A hidden level is not validated, and neither are the levels below it.
          subdivision_values = subdivision_fields.map { |field| address.send(field) unless field_overrides.hidden_fields.include?(field) }

          chain = Subdivision.chain(address_format.country_code, subdivision_values)
          errors.add(subdivision_fields[chain.unmatched_level], "should be valid") if chain.unmatched_level

          chain.subdivisions
        end

        define_method :verify_postal_code do |postal_code, subdivisions, address_format|
          # Nothing to validate.
          return if postal_code.blank?

          pattern = subdivisions.inject(address_format.postal_code_pattern) do |pattern, subdivision|
            subdivision_pattern = subdivision.postal_code_pattern
            next pattern if subdivision_pattern.blank?

            subdivision_pattern
          end

          if pattern
            # The pattern must match the provided value completely.
            match = postal_code.match(Regexp.new(pattern.gsub("\\\\", "\\").to_s, "i"))
            if match.nil? || match[0] != postal_code
              errors.add(AddressField::POSTAL_CODE, "should be valid")
              nil
            end
          end
        end
      end
    end
  end
end

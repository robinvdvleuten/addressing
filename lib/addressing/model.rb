# frozen_string_literal: true

module Addressing
  module Model
    def validates_address_format(
      fields: [:country_code, :administrative_area, :locality, :dependent_locality, :postal_code, :sorting_code, :address_line1, :address_line2, :organization, :given_name, :additional_name, :family_name, :locale], field_overrides: nil, **options)
      fields = Array(fields)
      field_overrides ||= FieldOverrides.new({})

      options[:if] ||= -> { fields.any? { |f| changes.key?(f.to_s) } } unless options[:unless]

      class_eval do
        validate :verify_address_format, **options

        define_method :verify_address_format do
          values = fields.each_with_object({}) { |f, v| v[f] = send(f) if self.respond_to?(f) }
          address = Address.new(**values)

          return unless address.country_code.present?

          address_format = AddressFormat.get(address.country_code)
          address_format.used_fields

          return unless address.country_code.present?

          address_format = AddressFormat.get(address.country_code)
          address_format.used_fields

          # Validate the presence of required fields.
          AddressFormatHelper::required_fields(address_format, field_overrides).each do |required_field|
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
          verify_postal_code(address.postal_code, subdivisions, address_format) if used_fields.include?(AddressField::POSTAL_CODE)
        end

        define_method :verify_subdivisions do |address, address_format, field_overrides|
          # No predefined subdivisions exist, nothing to validate against.
          return [] if address_format.subdivision_depth < 1

          subdivisions, _parents = address_format.used_subdivision_fields.each_with_index.inject([[], []]) do |(subdivisions, parents), (field, index)|
            # The field is empty or validation is disabled.
            break [subdivisions, parents] if address.send(field).blank? || field_overrides.hidden_fields.include?(field)

            parents << (index > 0 ? address.send(address_format.used_subdivision_fields[index - 1]) : address_format.country_code)
            subdivision = Subdivision.get(address.send(field), parents)
            if subdivision.nil?
              errors.add(field, "should be valid")
              break [subdivisions, parents]
            end

            subdivisions << subdivision
            # No predefined subdivisions below this level, stop here.
            break [subdivisions, parents] if subdivision.children.empty?

            [subdivisions, parents]
          end

          subdivisions
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
              return
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Addressing
  module Model
    # The error message for each kind of field violation.
    FIELD_VIOLATION_MESSAGES = {
      blank: "should not be blank",
      present: "should be blank",
      invalid: "should be valid"
    }.freeze
    private_constant :FIELD_VIOLATION_MESSAGES

    def validates_address_format(
      fields: Address::FIELDS, field_overrides: nil, verify_postal_code: true, **options
    )
      fields = Array(fields)
      field_overrides ||= FieldOverrides.new({})

      options[:if] ||= -> { fields.any? { |f| changes.key?(f.to_s) } } unless options[:unless]

      validate :validate_address_format, **options

      # A method rather than a block, so that a later call, in a subclass for
      # example, replaces the configuration of an earlier one.
      define_method :validate_address_format do
        values = fields.each_with_object({}) { |f, v| v[f] = send(f) if respond_to?(f) }
        address = Address.new(**values)

        AddressValidator.validate(address, field_overrides: field_overrides, verify_postal_code: verify_postal_code).each do |violation|
          errors.add(violation.field, violation.kind, message: FIELD_VIOLATION_MESSAGES.fetch(violation.kind))
        end
      end
      private :validate_address_format
    end
  end
end

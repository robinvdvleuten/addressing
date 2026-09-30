# frozen_string_literal: true

module Addressing
  # One field of an address that breaks a rule of the address format for its
  # country, together with the kind of rule it breaks. A blank country code is
  # also a field violation.
  #
  # field is the field as a symbol, such as :postal_code. kind is one of:
  #
  # - :blank, the field must not be blank.
  # - :present, the field must be blank.
  # - :invalid, the value matches no predefined subdivision or does not match
  #   the postal code pattern.
  #
  # The kinds match the error types of Rails.
  FieldViolation = Data.define(:field, :kind)
end

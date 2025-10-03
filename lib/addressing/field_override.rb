# frozen_string_literal: true

module Addressing
  class FieldOverride < Enum
    HIDDEN = "hidden"
    OPTIONAL = "optional"
    REQUIRED = "required"
  end

  class FieldOverrides
    attr_reader :hidden_fields, :optional_fields, :required_fields

    def initialize(definition)
      AddressField.assert_all_exist(definition.keys)
      FieldOverride.assert_all_exist(definition.values)

      # Group fields by their override type
      grouped = definition.group_by { |_field, override| override }
                          .transform_values { |pairs| pairs.map(&:first) }

      @hidden_fields = grouped[FieldOverride::HIDDEN] || []
      @optional_fields = grouped[FieldOverride::OPTIONAL] || []
      @required_fields = grouped[FieldOverride::REQUIRED] || []
    end
  end
end

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

      @hidden_fields = []
      @optional_fields = []
      @required_fields = []

      definition.each do |field, override|
        case override
        when FieldOverride::HIDDEN
          @hidden_fields << field
        when FieldOverride::OPTIONAL
          @optional_fields << field
        when FieldOverride::REQUIRED
          @required_fields << field
        end
      end
    end
  end
end

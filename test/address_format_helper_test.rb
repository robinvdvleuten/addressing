# frozen_string_literal: true

require_relative "test_helper"

class AddressFormatHelperTest < Minitest::Test
  def test_required_fields
    address_format = Addressing::AddressFormat.new(
      country_code: "US",
      format: "%given_name %family_name\n%organization\n%address_line1\n%address_line2\n%locality, %administrative_area %postal_code",
      required_fields: [
        Addressing::AddressField::ADMINISTRATIVE_AREA,
        Addressing::AddressField::LOCALITY,
        Addressing::AddressField::POSTAL_CODE,
      ]
    )

    field_overrides = Addressing::FieldOverrides.new({})
    expected_required_fields = [
      Addressing::AddressField::ADMINISTRATIVE_AREA,
      Addressing::AddressField::LOCALITY,
      Addressing::AddressField::POSTAL_CODE,
    ]
    assert_equal expected_required_fields, Addressing::AddressFormatHelper.required_fields(address_format, field_overrides)

    field_overrides = Addressing::FieldOverrides.new({
      Addressing::AddressField::ADMINISTRATIVE_AREA => Addressing::FieldOverride::HIDDEN,
      Addressing::AddressField::POSTAL_CODE => Addressing::FieldOverride::OPTIONAL,
      Addressing::AddressField::ADDRESS_LINE1 => Addressing::FieldOverride::REQUIRED,
    })
    expected_required_fields = [
      Addressing::AddressField::LOCALITY,
      Addressing::AddressField::ADDRESS_LINE1,
    ]
    assert_equal expected_required_fields, Addressing::AddressFormatHelper.required_fields(address_format, field_overrides)
  end
end

# frozen_string_literal: true

require_relative "test_helper"

class AddressFormatTest < Minitest::Test
  def test_get
    address_format = Addressing::AddressFormat.get("ES")

    # Confirm that the right class has been returned, a known value has
    # been successfully populated, and defaults have been merged.
    assert_instance_of Addressing::AddressFormat, address_format
    assert_equal "ES", address_format.country_code
    assert_equal Addressing::AdministrativeAreaType::PROVINCE, address_format.administrative_area_type
    assert_equal Addressing::LocalityType::CITY, address_format.locality_type
    assert_equal Addressing::PostalCodeType::POSTAL, address_format.postal_code_type
    assert_equal "\\d{5}", address_format.postal_code_pattern

    # Confirm that passing a lowercase country code works.
    another_address_format = Addressing::AddressFormat.get("es")
    assert_same another_address_format, address_format
  end

  def test_get_non_existing_address_format
    address_format = Addressing::AddressFormat.get("ZZ")
    assert_equal "ZZ", address_format.country_code
  end

  def test_all
    address_formats = Addressing::AddressFormat.all

    assert address_formats.key?("ES")
    assert_equal "ES", address_formats["ES"].country_code
    assert_equal Addressing::LocalityType::CITY, address_formats["ES"].locality_type

    assert address_formats.key?("RS")
    assert_equal "RS", address_formats["RS"].country_code
    assert_equal Addressing::LocalityType::CITY, address_formats["RS"].locality_type
  end

  def test_missing_property
    assert_raises ArgumentError do
      Addressing::AddressFormat.new(country_code: "US")
    end
  end

  def test_invalid_subdivision
    assert_raises ArgumentError do
      Addressing::AddressFormat.new(
        country_code: "US",
        format: "%given_name %family_name\n%organization\n%address_line1\n%address_line2\n%address_line3\n%dependent_locality",
        required_fields: [Addressing::AddressField::ADDRESS_LINE1],
        dependent_locality_type: "WRONG"
      )
    end
  end

  def test_valid
    definition = {
      country_code: "US",
      locale: "en",
      format: "%given_name %family_name\n%organization\n%address_line1\n%address_line2\n%address_line3\n%locality, %administrative_area %postal_code",
      # The local format is made up, US doesn't have one usually.
      local_format: "%postal_code\n%address_line1\n%organization\n%given_name %family_name",
      required_fields: [
        Addressing::AddressField::ADMINISTRATIVE_AREA,
        Addressing::AddressField::LOCALITY,
        Addressing::AddressField::POSTAL_CODE,
        Addressing::AddressField::ADDRESS_LINE1
      ],
      uppercase_fields: [
        Addressing::AddressField::ADMINISTRATIVE_AREA,
        Addressing::AddressField::LOCALITY
      ],
      administrative_area_type: Addressing::AdministrativeAreaType::STATE,
      locality_type: Addressing::LocalityType::CITY,
      dependent_locality_type: Addressing::DependentLocalityType::DISTRICT,
      postal_code_type: Addressing::PostalCodeType::ZIP,
      postal_code_pattern: "(\d{5})(?:[ -](\d{4}))?",
      # US doesn't use postal code prefixes, fake one for test purposes.
      postal_code_prefix: "US",
      subdivision_depth: 1
    }
    address_format = Addressing::AddressFormat.new(**definition)

    assert_equal definition[:country_code], address_format.country_code
    assert_equal definition[:locale], address_format.locale
    assert_equal definition[:format], address_format.format
    assert_equal definition[:local_format], address_format.local_format
    assert_equal definition[:required_fields], address_format.required_fields
    assert_equal definition[:uppercase_fields], address_format.uppercase_fields
    assert_equal definition[:administrative_area_type], address_format.administrative_area_type
    assert_equal definition[:locality_type], address_format.locality_type
    # The format has no %dependent_locality, the type must be nil.
    assert_nil address_format.dependent_locality_type
    assert_equal definition[:postal_code_type], address_format.postal_code_type
    assert_equal definition[:postal_code_pattern], address_format.postal_code_pattern
    assert_equal definition[:postal_code_prefix], address_format.postal_code_prefix
    assert_equal definition[:subdivision_depth], address_format.subdivision_depth

    expected_used_fields = [
      Addressing::AddressField::ADMINISTRATIVE_AREA,
      Addressing::AddressField::LOCALITY,
      Addressing::AddressField::POSTAL_CODE,
      Addressing::AddressField::ADDRESS_LINE1,
      Addressing::AddressField::ADDRESS_LINE2,
      Addressing::AddressField::ADDRESS_LINE3,
      Addressing::AddressField::ORGANIZATION,
      Addressing::AddressField::GIVEN_NAME,
      Addressing::AddressField::FAMILY_NAME
    ]
    assert_same_elements expected_used_fields, address_format.used_fields

    expected_used_subdivision_fields = [
      Addressing::AddressField::ADMINISTRATIVE_AREA,
      Addressing::AddressField::LOCALITY
    ]
    assert_same_elements expected_used_subdivision_fields, address_format.used_subdivision_fields
  end
end

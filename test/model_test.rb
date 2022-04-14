# frozen_string_literal: true

require_relative "test_helper"

class ModelTest < Minitest::Test
  def test_blank
    address = Address.new
    assert address.valid?
  end

  def test_andorra_valid
    address = Address.new(
      country_code: "AD",
      locality: "Parròquia d'Andorra la Vella",
      postal_code: "AD500",
      address_line1: "C. Prat de la Creu, 62-64",
      given_name: "Antoni",
      family_name: "Martí"
    )
    assert address.valid?
  end

  def test_andorra_invalid
    address = Address.new(
      country_code: "AD",
      locality: "INVALID",
      postal_code: "AD500",
      address_line1: "C. Prat de la Creu, 62-64",
      given_name: "Antoni",
      family_name: "Martí"
    )
    assert !address.valid?
    assert address.errors.key?(:locality)
  end

  def test_united_states_valid
    address = Address.new(
      country_code: "US",
      administrative_area: "CA",
      locality: "Mountain View",
      postal_code: "94043",
      address_line1: "1098 Alta Ave",
      given_name: "John",
      family_name: "Smith"
    )
    assert address.valid?
  end

  def test_united_states_invalid
    address = Address.new(
      country_code: "US",
      administrative_area: "CA",
      # Fails the format-level check.
      postal_code: "909",
      given_name: "John",
      family_name: "Smith"
    )
    assert !address.valid?
    assert address.errors.key?(:address_line1)
    assert address.errors.key?(:locality)
    assert address.errors.key?(:postal_code)
  end

  def test_united_states_subdivision_postal_code_pattern
    address = Address.new(
      country_code: "US",
      administrative_area: "CA",
      locality: "Mountain View",
      address_line1: "1098 Alta Ave",
      # Satisfies the format-level check, fails the subdivision-level one.
      postal_code: "84025",
      given_name: "John",
      family_name: "Smith"
    )
    assert !address.valid?
    assert address.errors.key?(:postal_code)
  end

  def test_china_valid
    address = Address.new(
      country_code: "CN",
      administrative_area: "Beijing Shi",
      locality: "Xicheng Qu",
      postal_code: "123456",
      address_line1: "Yitiao Lu",
      given_name: "John",
      family_name: "Smith"
    )
    assert address.valid?
  end

  def test_china_postal_code_bad_format
    address = Address.new(
      country_code: "CN",
      administrative_area: "Beijing Shi",
      locality: "Xicheng Qu",
      postal_code: "INVALID",
      given_name: "John",
      family_name: "Smith"
    )
    assert !address.valid?
    assert address.errors.key?(:postal_code)
    assert address.errors.key?(:address_line1)
  end

  def test_china_taiwan_valid
    address = Address.new(
      country_code: "CN",
      administrative_area: "Taiwan",
      locality: "Taichung City",
      dependent_locality: "INVALID",
      postal_code: "407",
      address_line1: "12345 Yitiao Lu",
      given_name: "John",
      family_name: "Smith"
    )
    assert !address.valid?
    assert address.errors.key?(:dependent_locality)
  end

  def test_china_taiwan_unknown_district
    address = Address.new(
      country_code: "CN",
      administrative_area: "Taiwan",
      locality: "Taichung City",
      dependent_locality: "Xitun District",
      postal_code: "407",
      address_line1: "12345 Yitiao Lu",
      given_name: "John",
      family_name: "Smith"
    )
    assert address.valid?
  end

  def test_japan_valid
    address = Address.new(
      country_code: "JP",
      administrative_area: "Kyoto",
      locality: "Shigeru Miyamoto",
      postal_code: "601-8501",
      address_line1: "11-1 Kamitoba-hokotate-cho",
      given_name: "Conan",
      family_name: "O'Brien"
    )
    assert address.valid?
  end

  def test_canada_mixed_case_postal_code
    address = Address.new(
      country_code: "CA",
      administrative_area: "QC",
      locality: "Montreal",
      postal_code: "H2b 2y5",
      sorting_code: "INVALID",
      address_line1: "11 East St'",
      given_name: "Joe",
      family_name: "Bloggs"
    )
    assert !address.valid?
    assert address.errors.key?(:sorting_code)
  end

  def test_canada_unused_fields
    address = Address.new(
      country_code: "CA",
      administrative_area: "QC",
      locality: "Montreal",
      postal_code: "H2b 2y5",
      address_line1: "11 East St'",
      given_name: "Joe",
      family_name: "Bloggs"
    )
    assert address.valid?
  end

  def test_german_address
    address = Address.new(
      country_code: "DE",
      locality: "Berlin",
      postal_code: "10553",
      address_line1: "Huttenstr. 50",
      organization: "BMW AG Niederkassung Berlin",
      given_name: "Dieter",
      family_name: "Diefendorf"
    )
    assert address.valid?

    # Testing with a empty city should fail.
    address.locality = nil
    assert !address.valid?
    assert address.errors.key?(:locality)
  end

  def test_irish_address
    address = Address.new(
      country_code: "IE",
      administrative_area: "Co. Donegal",
      locality: "Dublin",
      address_line1: "424 118 Avenue NW",
      given_name: "Conan",
      family_name: "O'Brien"
    )
    assert address.valid?

    # Test the same address but leave the county empty.
    # This address should be valid since county is not required.
    address.administrative_area = nil
    assert address.valid?
  end

  def test_empty_postal_code_reported_as_good_format
    address = Address.new(
      country_code: "CL",
      administrative_area: "Antofagasta",
      locality: "San Pedro de Atacama",
      postal_code: "",
      address_line1: "GUSTAVO LE PAIGE ST #159",
      given_name: "Conan",
      family_name: "O'Brien"
    )
    assert address.valid?

    # Now check for US addresses, which require a postal code. The following
    # address's postal code is wrong because it is missing a required field, not
    # because it doesn't match the expected postal code pattern.
    address = Address.new(
      country_code: "US",
      administrative_area: "CA",
      locality: "California",
      address_line1: "1098 Alta Ave",
      given_name: "John",
      family_name: "Smith"
    )
    assert !address.valid?
    assert address.errors.key?(:postal_code)
  end

  def test_overriding_required_fields
    address_klass = Class.new(Address) do
      validates_address_format field_overrides: Addressing::FieldOverrides.new({ "given_name" => Addressing::FieldOverride::OPTIONAL, "family_name" => Addressing::FieldOverride::OPTIONAL })
    end

    address = address_klass.new(
      country_code: "CN",
      administrative_area: "Beijing Shi",
      locality: "Xicheng Qu",
      postal_code: "123456",
      address_line1: "Yitiao Lu",
    )
    assert address.valid?
  end

  def test_hidden_postal_code_field
    address_klass = Class.new(Address) do
      validates_address_format field_overrides: Addressing::FieldOverrides.new({ "postal_code" => Addressing::FieldOverride::HIDDEN })
    end

    address = address_klass.new(
      country_code: "CN",
      administrative_area: "Beijing Shi",
      locality: "Xicheng Qu",
      address_line1: "Yitiao Lu",
      postal_code: "INVALID",
      given_name: "John",
      family_name: "Smith"
    )
    assert !address.valid?
    assert address.errors.key?(:postal_code)
  end

  def test_hidden_subdivision_field
    address_klass = Class.new(Address) do
      validates_address_format field_overrides: Addressing::FieldOverrides.new({ "administrative_area" => Addressing::FieldOverride::HIDDEN })
    end

    address = address_klass.new(
      country_code: "CN",
      administrative_area: "INVALID",
      locality: "Xicheng Qu",
      address_line1: "Yitiao Lu",
      postal_code: "123456",
      given_name: "John",
      family_name: "Smith"
    )
    assert !address.valid?
    assert address.errors.key?(:administrative_area)
  end

  def test_without_characters_in_address_fields
    address_klass = Class.new(Address) do
      validates_address_format without: /[@;&]/
    end

    address = address_klass.new(
      country_code: "CN",
      administrative_area: "Beijing Shi",
      locality: "Xich&eng Qu",
      address_line1: "Yiti@ao Lu",
      postal_code: "123456",
      given_name: "J;ohn",
      family_name: "Smith"
    )
    assert !address.valid?
    assert address.errors.key?(:locality)
    assert address.errors.key?(:address_line1)
    assert address.errors.key?(:given_name)
  end
end

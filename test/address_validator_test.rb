# frozen_string_literal: true

require_relative "test_helper"

class AddressValidatorTest < Minitest::Test
  def test_valid_address
    assert_equal [], validate(us_address)
  end

  def test_required_fields
    address = us_address.with_address_line1("").with_locality(nil)

    assert_equal [violation(:address_line1, :blank), violation(:locality, :blank)], validate(address)
  end

  def test_field_overrides
    field_overrides = Addressing::FieldOverrides.new({
      Addressing::AddressField::GIVEN_NAME => Addressing::FieldOverride::OPTIONAL,
      Addressing::AddressField::FAMILY_NAME => Addressing::FieldOverride::HIDDEN,
      Addressing::AddressField::ADDRESS_LINE2 => Addressing::FieldOverride::REQUIRED
    })

    address = us_address.with_given_name("").with_family_name("").with_address_line2("")
    assert_equal [violation(:address_line2, :blank)], validate(address, field_overrides: field_overrides)

    address = us_address.with_address_line2("Suite 100")
    assert_equal [violation(:family_name, :present)], validate(address, field_overrides: field_overrides)
  end

  def test_unused_fields
    address = us_address.with_sorting_code("CEDEX 1").with_dependent_locality("Downtown")

    assert_equal [violation(:dependent_locality, :present), violation(:sorting_code, :present)], validate(address)
  end

  def test_subdivision_without_match
    assert_equal [violation(:administrative_area, :invalid)], validate(us_address.with_administrative_area("XX"))
    assert_equal [violation(:dependent_locality, :invalid)], validate(taiwan_address.with_dependent_locality("INVALID"))
  end

  def test_subdivision_without_children
    address = taiwan_address.with_administrative_area("BJ").with_locality("Xicheng Qu").with_dependent_locality("Anywhere").with_postal_code("100032")

    assert_equal [], validate(address)
  end

  def test_hidden_subdivision_level
    field_overrides = Addressing::FieldOverrides.new({"administrative_area" => Addressing::FieldOverride::HIDDEN})

    # The levels below a hidden level are not checked either, and the postal
    # code falls back to the pattern of the country.
    address = taiwan_address.with_administrative_area("").with_locality("Nowhere").with_postal_code("400000")
    assert_equal [], validate(address, field_overrides: field_overrides)

    address = taiwan_address.with_administrative_area("INVALID").with_postal_code("407")
    assert_equal [violation(:administrative_area, :present), violation(:postal_code, :invalid)], validate(address, field_overrides: field_overrides)
  end

  def test_postal_code_pattern
    assert_equal [violation(:postal_code, :invalid)], validate(us_address.with_postal_code("909"))
    # The whole value must match.
    assert_equal [violation(:postal_code, :invalid)], validate(us_address.with_postal_code("94043x"))
    # A blank postal code is only reported as missing.
    assert_equal [violation(:postal_code, :blank)], validate(us_address.with_postal_code(""))
  end

  def test_subdivision_postal_code_pattern
    # Taiwan has its own pattern, which replaces the six digits of China.
    assert_equal [], validate(taiwan_address.with_postal_code("407"))
    assert_equal [violation(:postal_code, :invalid)], validate(taiwan_address.with_postal_code("40"))
  end

  def test_postal_code_pattern_ignores_case
    address = Addressing::Address.new(
      country_code: "CA",
      administrative_area: "QC",
      locality: "Montreal",
      postal_code: "H2b 2y5",
      address_line1: "11 East St",
      given_name: "Joe",
      family_name: "Bloggs"
    )

    assert_equal [], validate(address)
  end

  def test_without_postal_code_verification
    assert_equal [], validate(us_address.with_postal_code("909"), verify_postal_code: false)
  end

  def test_missing_country_code
    assert_equal [], validate(us_address.with_country_code(""))
    assert_equal [], validate(us_address.with_country_code(nil).with_sorting_code("CEDEX 1"))
  end

  def test_blank_values
    address = us_address.with_address_line1(" \u00A0\t").with_organization("".encode("UTF-16LE")).with_sorting_code(" ".encode("UTF-16LE"))

    assert_equal [violation(:address_line1, :blank)], validate(address)
  end

  def test_value_that_decides_its_own_blankness
    blank_value = Object.new
    def blank_value.blank? = true

    assert_equal [], validate(us_address.with_country_code(blank_value))
  end

  def test_validate_is_the_only_public_method
    refute_respond_to Addressing::AddressValidator, :new
  end

  private

  def validate(address, **options)
    Addressing::AddressValidator.validate(address, **options)
  end

  def violation(field, kind)
    Addressing::FieldViolation.new(field: field, kind: kind)
  end

  def taiwan_address
    Addressing::Address.new(
      country_code: "CN",
      administrative_area: "TW",
      locality: "Taichung City",
      dependent_locality: "Xitun District",
      postal_code: "407",
      address_line1: "12345 Yitiao Lu",
      given_name: "John",
      family_name: "Smith"
    )
  end

  def us_address
    Addressing::Address.new(
      country_code: "US",
      administrative_area: "CA",
      locality: "Mountain View",
      postal_code: "94043",
      address_line1: "1098 Alta Ave",
      given_name: "John",
      family_name: "Smith"
    )
  end
end

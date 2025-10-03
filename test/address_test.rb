# frozen_string_literal: true

require_relative "test_helper"

class AddressTest < Minitest::Test
  def test_constructor
    address = Addressing::Address.new(country_code: "US", administrative_area: "CA", locality: "Mountain View", dependent_locality: "MV", postal_code: "94043", sorting_code: "94044", address_line1: "1600 Amphitheatre Parkway", address_line2: "Google Bldg 41", address_line3: "Office 35", organization: "Google Inc.", given_name: "John", additional_name: "L.", family_name: "Smith", locale: "en")

    assert_equal "US", address.country_code
    assert_equal "CA", address.administrative_area
    assert_equal "Mountain View", address.locality
    assert_equal "MV", address.dependent_locality
    assert_equal "94043", address.postal_code
    assert_equal "94044", address.sorting_code
    assert_equal "1600 Amphitheatre Parkway", address.address_line1
    assert_equal "Google Bldg 41", address.address_line2
    assert_equal "Office 35", address.address_line3
    assert_equal "Google Inc.", address.organization
    assert_equal "John", address.given_name
    assert_equal "L.", address.additional_name
    assert_equal "Smith", address.family_name
    assert_equal "en", address.locale
  end

  def test_with_country_code
    address = Addressing::Address.new.with_country_code("US")
    assert_equal "US", address.country_code
  end

  def test_with_administrative_area
    address = Addressing::Address.new.with_administrative_area("CA")
    assert_equal "CA", address.administrative_area
  end

  def test_with_locality
    address = Addressing::Address.new.with_locality("Mountain View")
    assert_equal "Mountain View", address.locality
  end

  def test_with_dependent_locality
    # US doesn't use dependent localities, so there's no good example here.
    address = Addressing::Address.new.with_dependent_locality("MV")
    assert_equal "MV", address.dependent_locality
  end

  def test_with_postal_code
    address = Addressing::Address.new.with_postal_code("94043")
    assert_equal "94043", address.postal_code
  end

  def test_with_sorting_code
    address = Addressing::Address.new.with_sorting_code("94044")
    assert_equal "94044", address.sorting_code
  end

  def test_with_address_line1
    address = Addressing::Address.new.with_address_line1("1600 Amphitheatre Parkway")
    assert_equal "1600 Amphitheatre Parkway", address.address_line1
  end

  def test_with_address_line2
    address = Addressing::Address.new.with_address_line2("Google Bldg 41")
    assert_equal "Google Bldg 41", address.address_line2
  end

  def test_with_address_line3
    address = Addressing::Address.new.with_address_line3("Office 35")
    assert_equal "Office 35", address.address_line3
  end

  def test_with_organization
    address = Addressing::Address.new.with_organization("Google Inc.")
    assert_equal "Google Inc.", address.organization
  end

  def test_with_given_name
    address = Addressing::Address.new.with_given_name("John")
    assert_equal "John", address.given_name
  end

  def test_with_additional_name
    address = Addressing::Address.new.with_additional_name("L.")
    assert_equal "L.", address.additional_name
  end

  def test_with_family_name
    address = Addressing::Address.new.with_family_name("Smith")
    assert_equal "Smith", address.family_name
  end

  def test_with_locale
    address = Addressing::Address.new.with_locale("en")
    assert_equal "en", address.locale
  end
end

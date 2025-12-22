# frozen_string_literal: true

require_relative "test_helper"

class PostalLabelFormatterTest < Minitest::Test
  def setup
    @formatter = Addressing::PostalLabelFormatter.new
  end

  def test_missing_origin_country_code
    assert_raises ArgumentError do
      @formatter.format(Addressing::Address.new)
    end
  end

  def test_empty_address
    formatted_address = @formatter.format(Addressing::Address.new(country_code: "US"), origin_country: "US")
    assert_formatted_address [], formatted_address
  end

  def test_united_states_address
    address = Addressing::Address.new
      .with_country_code("US")
      .with_administrative_area("CA")
      .with_locality("Mt View")
      .with_postal_code("94043")
      .with_address_line1("1098 Alta Ave")

    # Test a US address formatted for sending from the US.
    expected_lines = [
      "1098 Alta Ave",
      "MT VIEW, CA 94043"
    ]

    formatted_address = @formatter.format(address, origin_country: "US")
    assert_formatted_address expected_lines, formatted_address

    # Test a US address formatted for sending from France.
    expected_lines = [
      "1098 Alta Ave",
      "MT VIEW, CA 94043",
      "ÉTATS-UNIS - UNITED STATES"
    ]

    formatted_address = @formatter.format(address, locale: "FR", origin_country: "FR")
    assert_formatted_address expected_lines, formatted_address
  end

  def test_japan_address_shipped_from_france
    address = Addressing::Address.new
      .with_country_code("JP")
      .with_administrative_area("01")
      .with_locality("Some City")
      .with_address_line1("Address Line 1")
      .with_address_line2("Address Line 2")
      .with_address_line3("Address Line 3")
      .with_postal_code("04")
      .with_locale("ja")

    # Test a JP address formatted for sending from France.
    expected_lines = [
      "JAPON - JAPAN",
      "〒04",
      "北海道Some City",
      "Address Line 1",
      "Address Line 2",
      "Address Line 3"
    ]

    formatted_address = @formatter.format(address, locale: "fr", origin_country: "FR")
    assert_formatted_address expected_lines, formatted_address
  end

  def test_address_leading_post_prefix
    address = Addressing::Address.new
      .with_country_code("HR")
      .with_locality("Zagreb")
      .with_postal_code("10105")

    # Domestic mail shouldn't have the postal code prefix added.
    expected_lines = [
      "10105 ZAGREB"
    ]

    formatted_address = @formatter.format(address, origin_country: "HR")
    assert_formatted_address expected_lines, formatted_address

    # International mail should have the postal code prefix added.
    expected_lines = [
      "HR-10105 ZAGREB",
      "CROATIA"
    ]

    formatted_address = @formatter.format(address, origin_country: "FR")
    assert_formatted_address expected_lines, formatted_address
  end

  def test_united_states_address_with_upcase_disabled
    address = Addressing::Address.new
      .with_country_code("US")
      .with_administrative_area("CA")
      .with_locality("Mt View")
      .with_postal_code("94043")
      .with_address_line1("1098 Alta Ave")

    # Test a US address formatted for sending from the US.
    expected_lines = [
      "1098 Alta Ave",
      "Mt View, CA 94043"
    ]

    formatted_address = @formatter.format(address, origin_country: "US", upcase: false)
    assert_formatted_address expected_lines, formatted_address

    # Test a US address formatted for sending from France.
    expected_lines = [
      "1098 Alta Ave",
      "Mt View, CA 94043",
      "États-Unis - United States"
    ]

    formatted_address = @formatter.format(address, locale: "FR", origin_country: "FR", upcase: false)
    assert_formatted_address expected_lines, formatted_address
  end
end

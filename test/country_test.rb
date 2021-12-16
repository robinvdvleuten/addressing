# frozen_string_literal: true

require_relative "test_helper"

class CountryTest < Minitest::Test
  def test_get
    # Explicit locale.
    country = Addressing::Country.get("FR", "es")
    assert_instance_of Addressing::Country, country
    assert_equal "FR", country.country_code
    assert_equal "Francia", country.name
    assert_equal "FRA", country.three_letter_code
    assert_equal "250", country.numeric_code
    assert_equal "EUR", country.currency_code
    assert_equal "es", country.locale

    # Lowercase country code.
    country = Addressing::Country.get("fr", "de")
    assert_instance_of Addressing::Country, country
    assert_equal "FR", country.country_code
    assert_equal "Frankreich", country.name
    assert_equal "de", country.locale

    # Fallback locale.
    country = Addressing::Country.get("FR", "INVALID-LOCALE")
    assert_instance_of Addressing::Country, country
    assert_equal "FR", country.country_code
    assert_equal "France", country.name
    assert_equal "en", country.locale
  end

  def test_get_invalid_country
    assert_raises Addressing::UnknownCountryError do
      Addressing::Country.get("INVALID")
    end
  end

  def test_all
    # Explicit locale.
    countries = Addressing::Country.all("es")
    assert countries.key?("FR")
    assert countries.key?("US")
    assert_equal "Francia", countries["FR"].name
    assert_equal "Estados Unidos", countries["US"].name

    # Default locale.
    countries = Addressing::Country.all
    assert countries.key?("FR")
    assert countries.key?("US")
    assert_equal "France", countries["FR"].name
    assert_equal "United States", countries["US"].name

    # Fallback locale.
    countries = Addressing::Country.all("INVALID-LOCALE")
    assert countries.key?("FR")
    assert countries.key?("US")
    assert_equal "France", countries["FR"].name
    assert_equal "United States", countries["US"].name
  end

  def test_list
    # Explicit locale.
    list = Addressing::Country.list("es")
    assert list >= {"FR" => "Francia", "US" => "Estados Unidos"}

    # Default locale.
    list = Addressing::Country.list
    assert list >= {"FR" => "France", "US" => "United States"}

    # Fallback locale.
    list = Addressing::Country.list("INVALID-LOCALE")
    assert list >= {"FR" => "France", "US" => "United States"}
  end

  def test_missing_property
    assert_raises ArgumentError do
      Addressing::Country.new
    end
  end

  def test_valid
    country = Addressing::Country.new(
      country_code: "DE",
      name: "Allemagne",
      three_letter_code: "DEU",
      numeric_code: "276",
      currency_code: "EUR",
      locale: "fr"
    )

    assert_equal "DE", country.to_s
    assert_equal "DE", country.country_code
    assert_equal "Allemagne", country.name
    assert_equal "DEU", country.three_letter_code
    assert_equal "276", country.numeric_code
    assert_equal "EUR", country.currency_code
    assert_equal ["Europe/Berlin", "Europe/Zurich"], country.timezones
    assert_equal "fr", country.locale
  end
end

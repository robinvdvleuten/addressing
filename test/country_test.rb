# frozen_string_literal: true

require_relative "test_helper"

class CountryTest < Minitest::Test
  include FixtureData

  def test_get
    # Explicit locale.
    country = Addressing::Country.get("FR", "es")
    assert_instance_of Addressing::Country, country
    assert_equal "FR", country.country_code
    assert_equal "Francia de prueba", country.name
    assert_equal "FRX", country.three_letter_code
    assert_equal "901", country.numeric_code
    assert_equal "EUX", country.currency_code
    assert_equal "es", country.locale

    # Lowercase country code, locale resolved through its parent.
    country = Addressing::Country.get("fr", "es-MX")
    assert_instance_of Addressing::Country, country
    assert_equal "FR", country.country_code
    assert_equal "Francia latina de prueba", country.name
    assert_equal "es-419", country.locale

    # Fallback locale.
    country = Addressing::Country.get("FR", "INVALID-LOCALE")
    assert_instance_of Addressing::Country, country
    assert_equal "FR", country.country_code
    assert_equal "Fixture France", country.name
    assert_equal "en", country.locale
  end

  def test_get_invalid_country
    assert_raises Addressing::UnknownCountryError do
      Addressing::Country.get("INVALID")
    end
  end

  def test_get_unavailable_locale_without_fallback
    assert_raises Addressing::UnknownLocaleError do
      Addressing::Country.get("FR", "de", "de")
    end
  end

  def test_all
    # Explicit locale.
    countries = Addressing::Country.all("es")
    assert_equal ["FR", "US", "XA"], countries.keys
    assert_equal "Francia de prueba", countries["FR"].name
    assert_equal "Estados de prueba", countries["US"].name
    assert_equal "USX", countries["US"].three_letter_code

    # Default locale.
    countries = Addressing::Country.all
    assert_equal "Fixture France", countries["FR"].name
    assert_equal "Fixture States", countries["US"].name

    # Fallback locale.
    countries = Addressing::Country.all("INVALID-LOCALE")
    assert_equal "Fixture France", countries["FR"].name
    assert_equal "Fixture States", countries["US"].name
  end

  def test_list
    # Explicit locale.
    assert_equal({"FR" => "Francia de prueba", "US" => "Estados de prueba", "XA" => "Tierra de prueba"}, Addressing::Country.list("es"))

    # Default locale.
    assert_equal({"FR" => "Fixture France", "US" => "Fixture States", "XA" => "Fixtureland"}, Addressing::Country.list)

    # Fallback locale.
    assert_equal({"FR" => "Fixture France", "US" => "Fixture States", "XA" => "Fixtureland"}, Addressing::Country.list("INVALID-LOCALE"))
  end

  def test_list_cannot_change_the_cached_names
    Addressing::Country.list["FR"] = "Changed"

    assert_equal "Fixture France", Addressing::Country.list["FR"]
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

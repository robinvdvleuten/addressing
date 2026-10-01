# frozen_string_literal: true

require_relative "test_helper"

# The behavioral tests run against fixtures. These check that each reader
# still loads the data that ships with the gem.
class ShippedDataTest < Minitest::Test
  def test_country
    country = Addressing::Country.get("BR", "pt")

    assert_equal "Brasil", country.name
    assert_equal "BRA", country.three_letter_code
    assert_operator Addressing::Country.list.size, :>, 200
  end

  def test_subdivision
    chain = Addressing::Subdivision.chain("BR", ["CE", "Fortaleza"])

    assert_equal ["Ceará", "Fortaleza"], chain.subdivisions.map(&:name)
  end

  def test_locale
    assert_equal ["zh-Hans-CN", "zh-Hans", "zh"], Addressing::Locale.candidates("zh-CN")
  end
end

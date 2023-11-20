# frozen_string_literal: true

require_relative "test_helper"

class EnumTest < Minitest::Test
  def test_all
    expected_values = {EIR: "eircode", PIN: "pin", POSTAL: "postal", ZIP: "zip"}
    assert_same_elements expected_values, Addressing::PostalCodeType.all
  end

  def test_key
    assert_equal :ZIP, Addressing::PostalCodeType.key("zip")
    assert_nil Addressing::PostalCodeType.key("invalid")
  end

  def test_exists
    assert Addressing::PostalCodeType.exists?("zip")
    refute Addressing::PostalCodeType.exists?("invalid")
  end

  def test_assert_exists
    assert_raises ArgumentError do
      Addressing::PostalCodeType.assert_exists("invalid")
    end
  end

  def test_assert_all_exist
    assert_raises ArgumentError do
      Addressing::PostalCodeType.assert_all_exist(["zip", "invalid"])
    end
  end
end

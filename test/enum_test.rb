# frozen_string_literal: true

require_relative "test_helper"

class EnumTest < Minitest::Test
  def test_all
    expected_values = {FULL: "full", START: "start"}
    assert_same_elements expected_values, Addressing::PatternType.all
  end

  def test_key
    assert_equal :FULL, Addressing::PatternType.key("full")
    assert_nil Addressing::PatternType.key("invalid")
  end

  def test_exists
    assert Addressing::PatternType.exists?("start")
    refute Addressing::PatternType.exists?("invalid")
  end

  def test_assert_exists
    assert_raises ArgumentError do
      Addressing::PatternType.assert_exists("invalid")
    end
  end

  def test_assert_all_exist
    assert_raises ArgumentError do
      Addressing::PatternType.assert_all_exist(["start", "invalid"])
    end
  end
end

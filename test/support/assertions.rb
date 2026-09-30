# frozen_string_literal: true

module Minitest::Assertions
  def assert_formatted_address(expected_lines, formatted_address, msg = nil)
    assert_equal expected_lines.join("\n"), formatted_address, msg
  end

  def assert_same_elements(expected, current, msg = nil)
    assert_equal expected.tally, current.tally, msg
  end
end

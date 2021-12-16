# frozen_string_literal: true

module Minitest::Assertions
  def assert_formatted_address(expected_lines, formatted_address, msg = nil)
    assert_equal expected_lines.join("\n"), formatted_address, msg
  end

  def assert_same_elements(expected, current, msg = nil)
    assert expected_h = expected.each_with_object({}) { |e, h| h[e] ||= expected.count { |i| i == e } }
    assert current_h = current.each_with_object({}) { |e, h| h[e] ||= current.count { |i| i == e } }

    assert_equal(expected_h, current_h, msg)
  end
end

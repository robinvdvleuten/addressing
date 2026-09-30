# frozen_string_literal: true

require_relative "test_helper"

# The data files are UTF-8 and must be read as such, whatever the process locale.
class DataEncodingTest < Minitest::Test
  def setup
    @default_external = Encoding.default_external
    set_default_external(Encoding::US_ASCII)
    reset_definitions
  end

  def teardown
    set_default_external(@default_external)
    reset_definitions
  end

  def test_country_names_are_utf8
    countries = Addressing::Country.list("es")
    assert_equal "España", countries["ES"]
    assert_equal Encoding::UTF_8, countries["ES"].encoding
  end

  def test_subdivision_names_are_utf8
    subdivision = Addressing::Subdivision.get("CE", ["BR"])
    assert_equal "Ceará", subdivision.name
    assert_equal Encoding::UTF_8, subdivision.name.encoding
  end

  private

  # Ruby warns when the default external encoding changes.
  def set_default_external(encoding)
    verbose, $VERBOSE = $VERBOSE, nil
    Encoding.default_external = encoding
  ensure
    $VERBOSE = verbose
  end

  def reset_definitions
    Addressing::Country.instance_variable_set(:@definitions, nil)
    Addressing::Subdivision.instance_variable_set(:@definitions, nil)
    Addressing::Subdivision.instance_variable_set(:@parents, nil)
  end
end

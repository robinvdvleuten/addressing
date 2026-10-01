# frozen_string_literal: true

require_relative "test_helper"

# Formats addresses of the fixture country XA, with a format string written
# in each test, so that no test depends on the data that ships with the gem.
class FormattingTest < Minitest::Test
  def setup
    @formatter = Addressing::DefaultFormatter.new(html: false)
    @postal_label_formatter = Addressing::PostalLabelFormatter.new
  end

  def test_unrecognized_option
    assert_raises(ArgumentError) { Addressing::DefaultFormatter.new(unrecognized: "123") }
    assert_raises(ArgumentError) { @formatter.format(address, unrecognized: "123") }
  end

  def test_invalid_html_option
    assert_raises(ArgumentError) { Addressing::DefaultFormatter.new(html: "INVALID") }
    assert_raises(ArgumentError) { @formatter.format(address, html: "INVALID") }
  end

  def test_invalid_html_tag_option
    ["", nil, 1, "p onclick=\"alert(1)\"", "<p>", "1p"].each do |html_tag|
      error = assert_raises(ArgumentError) { Addressing::DefaultFormatter.new(html_tag: html_tag) }
      assert_equal "The option `html_tag` must be an HTML tag name.", error.message

      assert_raises(ArgumentError) { @formatter.format(address, html_tag: html_tag) }
    end
  end

  def test_valid_html_tag_option
    with_address_format(format: "%locality") do
      ["div", :div, "H1", "address-block"].each do |html_tag|
        lines = @formatter.format(address, html: true, html_tag: html_tag).lines(chomp: true)

        assert_equal "<#{html_tag} translate=\"no\">", lines.first
        assert_equal "</#{html_tag}>", lines.last
      end
    end
  end

  def test_invalid_locale_option
    [nil, :fr, 1].each do |locale|
      error = assert_raises(ArgumentError) { Addressing::DefaultFormatter.new(locale: locale) }
      assert_equal "The option `locale` must be a string.", error.message

      assert_raises(ArgumentError) { @formatter.format(address, locale: locale) }
    end
  end

  def test_unknown_locale_falls_back
    with_address_format(format: "%locality") do
      assert_equal "Fixtureland", @formatter.format(address, locale: "xx")
    end
  end

  def test_invalid_origin_country_option
    message = "The option `origin_country` must be a non-empty string."

    ["", nil, :fr, 1].each do |origin_country|
      error = assert_raises(ArgumentError) { Addressing::PostalLabelFormatter.new(origin_country: origin_country) }
      assert_equal message, error.message, origin_country.inspect

      error = assert_raises(ArgumentError) { @postal_label_formatter.format(address, origin_country: origin_country) }
      assert_equal message, error.message, origin_country.inspect
    end
  end

  def test_missing_origin_country_option
    error = assert_raises(ArgumentError) { @postal_label_formatter.format(address) }

    assert_equal "The option `origin_country` must be a non-empty string.", error.message
  end

  def test_empty_field_between_values_keeps_the_separator_before_it
    with_address_format(format: "%locality, %administrative_area %postal_code") do
      assert_equal "Springfield, 12345\nFixtureland", @formatter.format(address(locality: "Springfield", postal_code: "12345"))
    end
  end

  def test_leading_empty_field_drops_its_separator
    with_address_format(format: "%organization, %locality") do
      assert_equal "Springfield\nFixtureland", @formatter.format(address(locality: "Springfield"))
    end
  end

  def test_line_with_only_empty_fields_disappears
    with_address_format(format: "%address_line1\n%address_line2\n%locality") do
      assert_equal "1 Main St\nSpringfield\nFixtureland", @formatter.format(address(address_line1: "1 Main St", locality: "Springfield"))
    end
  end

  def test_punctuation_and_whitespace_are_cleaned_up
    with_address_format(format: "- %address_line1\n%locality") do
      assert_equal "1 Main St\nSpringfield\nFixtureland", @formatter.format(address(address_line1: "1  Main   St", locality: " Springfield, "))
    end
  end

  def test_country_goes_on_top_of_the_local_format
    with_address_format(format: "%locality\n%postal_code", local_format: "%postal_code\n%locality", locale: "es") do
      assert_equal "Fixtureland\n12345\nSpringfield", @formatter.format(address(locality: "Springfield", postal_code: "12345", locale: "es-MX"))
      assert_equal "Springfield\n12345\nFixtureland", @formatter.format(address(locality: "Springfield", postal_code: "12345", locale: "fr"))
    end
  end

  def test_values_are_escaped_in_html_and_stripped_in_text
    with_address_format(format: "%locality") do
      locality = "<b>A & B</b>"

      expected_html = [
        "<p translate=\"no\">",
        "<span class=\"locality\">&lt;b&gt;A &amp; B&lt;/b&gt;</span><br>",
        "<span class=\"country\">Fixtureland</span>",
        "</p>"
      ]
      assert_formatted_address expected_html, @formatter.format(address(locality: locality), html: true)
      assert_equal "A & B\nFixtureland", @formatter.format(address(locality: locality))
    end
  end

  def test_postal_label_for_domestic_mail
    with_postal_label_format do
      assert_equal "1 Main St\n12345 SPRINGFIELD", @postal_label_formatter.format(postal_label_address, origin_country: "xa")
    end
  end

  def test_postal_label_for_international_mail
    with_postal_label_format do
      # The names in the locale and in English are the same, so English once.
      assert_equal "1 Main St\nXA-12345 SPRINGFIELD\nFIXTURELAND", @postal_label_formatter.format(postal_label_address, origin_country: "FR")
      assert_equal "1 Main St\nXA-12345 SPRINGFIELD\nTIERRA DE PRUEBA - FIXTURELAND", @postal_label_formatter.format(postal_label_address, origin_country: "FR", locale: "es")
    end
  end

  private

  def with_postal_label_format(&)
    with_address_format(format: "%address_line1\n%postal_code %locality", uppercase_fields: ["locality"], postal_code_prefix: "XA-", &)
  end

  def postal_label_address
    address(address_line1: "1 Main St", locality: "Springfield", postal_code: "12345")
  end

  def address(**values)
    Addressing::Address.new(country_code: "XA", **values)
  end
end

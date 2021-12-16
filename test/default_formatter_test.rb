# frozen_string_literal: true

require_relative "test_helper"

class DefaultFormatterTest < Minitest::Test
  def setup
    @formatter = Addressing::DefaultFormatter.new
  end

  def test_unrecognized_option
    assert_raises(ArgumentError) do
      Addressing::DefaultFormatter.new(unrecognized: "123")
    end
  end

  def test_invalid_option
    assert_raises(ArgumentError) do
      Addressing::DefaultFormatter.new(html: "INVALID")
    end
  end

  def test_andorra_address
    address = (Addressing::Address.new)
      .with_country_code("AD")
      .with_locality("Parròquia d'Andorra la Vella")
      .with_postal_code("AD500")
      .with_address_line1("C. Prat de la Creu, 62-64")

    # Andorra has no predefined administrative areas, but it does have
    # predefined localities, which must be shown.
    expected_text_lines = [
      "C. Prat de la Creu, 62-64",
      "AD500 Parròquia d'Andorra la Vella",
      "Andorra"
    ]

    text_address = @formatter.format(address, html: false)
    assert_formatted_address expected_text_lines, text_address
  end

  def test_el_salvadar_address
    address = (Addressing::Address.new)
      .with_country_code("SV")
      .with_administrative_area("Ahuachapán")
      .with_locality("Ahuachapán")
      .with_address_line1("4A Avenida Norte")

    expected_html_lines = [
      '<p translate="no">',
      '<span class="address-line1">4A Avenida Norte</span><br>',
      '<span class="locality">Ahuachapán</span><br>',
      '<span class="administrative-area">Ahuachapán</span><br>',
      '<span class="country">El Salvador</span>',
      "</p>"
    ]

    html_address = @formatter.format(address)
    assert_formatted_address expected_html_lines, html_address

    expected_text_lines = [
      "4A Avenida Norte",
      "Ahuachapán",
      "Ahuachapán",
      "El Salvador"
    ]

    text_address = @formatter.format(address, html: false)
    assert_formatted_address expected_text_lines, text_address

    address = address.with_postal_code("CP 2101")

    expected_html_lines = [
      '<p translate="no">',
      '<span class="address-line1">4A Avenida Norte</span><br>',
      '<span class="postal-code">CP 2101</span>-<span class="locality">Ahuachapán</span><br>',
      '<span class="administrative-area">Ahuachapán</span><br>',
      '<span class="country">El Salvador</span>',
      "</p>"
    ]

    html_address = @formatter.format(address)
    assert_formatted_address expected_html_lines, html_address

    expected_text_lines = [
      "4A Avenida Norte",
      "CP 2101-Ahuachapán",
      "Ahuachapán",
      "El Salvador"
    ]

    text_address = @formatter.format(address, html: false)
    assert_formatted_address expected_text_lines, text_address
  end

  def test_taiwan_address
    # Real addresses in the major-to-minor order would be completely in
    # Traditional Chinese. That's not the case here, for readability.
    address = (Addressing::Address.new)
      .with_country_code("TW")
      .with_administrative_area("Taipei City")
      .with_locality("Da'an District")
      .with_address_line1("Sec. 3 Hsin-yi Rd.")
      .with_postal_code("106")
      # Any HTML in the fields is supposed to be removed when formatting
      # for text, and escaped when formatting for html.
      .with_organization("Giant <h2>Bike</h2> Store")
      .with_given_name("Te-Chiang")
      .with_family_name("Liu")
      .with_locale("zh-Hant")

    expected_html_lines = [
      '<p translate="no" class="address postal-address">',
      '<span class="country">台灣</span><br>',
      '<span class="postal-code">106</span><br>',
      '<span class="administrative-area">台北市</span><span class="locality">大安區</span><br>',
      '<span class="address-line1">Sec. 3 Hsin-yi Rd.</span><br>',
      '<span class="organization">Giant &lt;h2&gt;Bike&lt;/h2&gt; Store</span><br>',
      '<span class="family-name">Liu</span> <span class="given-name">Te-Chiang</span>',
      "</p>"
    ]

    html_address = @formatter.format(address, locale: "zh-Hant", html_attributes: {translate: "no", class: ["address", "postal-address"]})
    assert_formatted_address expected_html_lines, html_address

    expected_text_lines = [
      "台灣",
      "106",
      "台北市大安區",
      "Sec. 3 Hsin-yi Rd.",
      "Giant Bike Store",
      "Liu Te-Chiang"
    ]

    text_address = @formatter.format(address, html: false, locale: "zh-Hant")
    assert_formatted_address expected_text_lines, text_address
  end

  def test_united_states_incomplete_address
    address = (Addressing::Address.new)
      .with_country_code("US")
      .with_administrative_area("CA")
      .with_postal_code("94043")
      .with_address_line1("1098 Alta Ave")

    expected_html_lines = [
      '<p translate="no">',
      '<span class="address-line1">1098 Alta Ave</span><br>',
      '<span class="administrative-area">CA</span> <span class="postal-code">94043</span><br>',
      '<span class="country">United States</span>',
      "</p>"
    ]

    html_address = @formatter.format(address)
    assert_formatted_address expected_html_lines, html_address

    expected_text_lines = [
      "1098 Alta Ave",
      "CA 94043",
      "United States"
    ]

    text_address = @formatter.format(address, html: false)
    assert_formatted_address expected_text_lines, text_address

    # Now add the locality, but remove the administrative area.
    address = address.with_locality("Mountain View").with_administrative_area("")

    expected_html_lines = [
      '<p translate="no">',
      '<span class="address-line1">1098 Alta Ave</span><br>',
      '<span class="locality">Mountain View</span>, <span class="postal-code">94043</span><br>',
      '<span class="country">United States</span>',
      "</p>"
    ]

    html_address = @formatter.format(address)
    assert_formatted_address expected_html_lines, html_address

    expected_text_lines = [
      "1098 Alta Ave",
      "Mountain View, 94043",
      "United States"
    ]

    text_address = @formatter.format(address, html: false)
    assert_formatted_address expected_text_lines, text_address
  end
end

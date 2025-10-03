# frozen_string_literal: true

module Addressing
  class PostalLabelFormatter < DefaultFormatter
    DEFAULT_OPTIONS = {
      locale: DEFAULT_LOCALE,
      html: false,
      html_tag: "p",
      html_attributes: {translate: "no"},
      origin_country: ""
    }

    protected

    def build_view(address, address_format, options)
      raise ArgumentError, "The origin_country option cannot be empty." if options[:origin_country].empty?

      view = super
      view = view.map do |key, element|
        # Uppercase fields where required by the format.
        element[:value] = element[:value].upcase if address_format.uppercase_fields.include?(key)
        [key, element]
      end.to_h

      # Handle international mailing.
      if address.country_code != options[:origin_country]
        # Prefix the postal code.
        field = AddressField::POSTAL_CODE

        if view.key?(field)
          view[field][:value] = [address_format.postal_code_prefix, view[field][:value]].join
        end

        # Universal Postal Union says: "The name of the country of
        # destination shall be written preferably in the language of the
        # country of origin. To avoid any difficulty in the countries of
        # transit, it is desirable for the name of the country of
        # destination to be added in an internationally known language.
        country = view["country"][:value]
        english_countries = Country.list("en")
        english_country = english_countries[address.country_code]

        if country != english_country
          country += " - #{english_country}"
        end

        view["country"][:value] = country.upcase
      else
        # The country is not written in case of domestic mailing.
        view["country"][:value] = ""
      end

      view
    end
  end
end

# frozen_string_literal: true

module Addressing
  # Provides country information including names, codes, currency, and timezones.
  #
  # Country names are available in over 250 locales powered by CLDR data.
  #
  # @example Get a country by code
  #   brazil = Addressing::Country.get('BR')
  #   brazil.name          # => "Brazil"
  #   brazil.currency_code # => "BRL"
  #
  # @example Get all countries
  #   countries = Addressing::Country.all('fr-FR')
  #
  # @example Get a simple list of countries
  #   list = Addressing::Country.list('en')
  class Country
    class << self
      # Gets a Country instance for the provided country code.
      #
      # @param country_code [String] ISO 3166-1 alpha-2 country code
      # @param locale [String] Locale for the country name (default: "en")
      # @param fallback_locale [String] Fallback locale if requested locale is unavailable
      # @return [Country] Country instance
      # @raise [UnknownCountryError] if the country code is not recognized
      def get(country_code, locale = "en", fallback_locale = "en")
        country_code = country_code.upcase

        raise UnknownCountryError.new(country_code) unless base_definitions.key?(country_code)

        locale = Locale.resolve(available_locales, locale, fallback_locale)

        build(country_code, load_definitions(locale)[country_code], locale)
      end

      # Gets all Country instances.
      #
      # @param locale [String] Locale for country names (default: "en")
      # @param fallback_locale [String] Fallback locale if requested locale is unavailable
      # @return [Hash<String, Country>] Hash of country code => Country instance
      def all(locale = "en", fallback_locale = "en")
        locale = Locale.resolve(available_locales, locale, fallback_locale)

        load_definitions(locale).to_h do |country_code, country_name|
          [country_code, build(country_code, country_name, locale)]
        end
      end

      # Gets a list of country codes and names.
      #
      # @param locale [String] Locale for country names (default: "en")
      # @param fallback_locale [String] Fallback locale if requested locale is unavailable
      # @return [Hash<String, String>] Hash of country code => country name
      def list(locale = "en", fallback_locale = "en")
        locale = Locale.resolve(available_locales, locale, fallback_locale)

        load_definitions(locale).dup
      end

      protected

      def build(country_code, name, locale)
        base_definition = base_definitions[country_code]

        new(
          country_code: country_code,
          name: name,
          three_letter_code: base_definition["three_letter_code"],
          numeric_code: base_definition["numeric_code"],
          currency_code: base_definition["currency_code"],
          locale: locale
        )
      end

      # Loads the country definitions for the provided locale.
      def load_definitions(locale)
        (@definitions ||= {})[locale] ||= begin
          filename = File.join(File.expand_path("../../../data/country", __FILE__).to_s, "#{locale}.json")
          JSON.parse(File.read(filename, encoding: "UTF-8"))
        end
      end

      # Gets the locales that have country names, one data file each.
      def available_locales
        @available_locales ||= Dir[File.expand_path("../../../data/country/*.json", __FILE__)].map { |filename| File.basename(filename, ".json") }.sort
      end

      # Gets the base country definitions.
      #
      # Contains data common to all locales: three letter code, numeric code, currency code.
      def base_definitions
        @base_definitions ||= begin
          filename = File.expand_path("../../../data/countries.json", __FILE__)
          JSON.parse(File.read(filename, encoding: "UTF-8"))
        end
      end
    end

    attr_reader :country_code, :name, :three_letter_code, :numeric_code, :currency_code, :locale

    def initialize(definition = {})
      # Validate the presence of required properties.
      [:country_code, :name, :locale].each do |required_property|
        if definition[required_property].nil?
          raise ArgumentError, "Missing required property #{required_property}."
        end
      end

      @country_code = definition[:country_code]
      @name = definition[:name]
      @three_letter_code = definition[:three_letter_code]
      @numeric_code = definition[:numeric_code]
      @currency_code = definition[:currency_code]
      @locale = definition[:locale]
    end

    # Gets the timezones.
    #
    # Note that a country can span more than one timezone.
    # For example, Germany has ["Europe/Berlin", "Europe/Busingen"].
    def timezones
      @timezones ||= TZInfo::Country.get(@country_code).zone_identifiers
    end

    # Gets the string representation of the Country.
    def to_s
      @country_code
    end
  end
end

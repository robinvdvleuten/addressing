# frozen_string_literal: true

module Addressing
  # Base error class for all Addressing errors
  class Error < StandardError; end

  # Raised when an unknown country code is provided
  class UnknownCountryError < Error
    def initialize(country_code)
      super("Unknown country code: #{country_code}")
      @country_code = country_code
    end

    attr_reader :country_code
  end

  # Raised when an unknown locale is provided
  class UnknownLocaleError < Error
    def initialize(locale)
      super("Unknown locale: #{locale}")
      @locale = locale
    end

    attr_reader :locale
  end

  # Raised when an invalid argument is provided
  class InvalidArgumentError < Error; end
end

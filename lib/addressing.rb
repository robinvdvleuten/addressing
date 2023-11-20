# frozen_string_literal: true

require "cgi"
require "digest"
require "json"

require "addressing/enum"
require "addressing/address"
require "addressing/address_field"
require "addressing/address_format"
require "addressing/administrative_area_type"
require "addressing/country"
require "addressing/default_formatter"
require "addressing/dependent_locality_type"
require "addressing/field_override"
require "addressing/lazy_subdivisions"
require "addressing/locale"
require "addressing/locality_type"
require "addressing/postal_code_type"
require "addressing/postal_label_formatter"
require "addressing/subdivision"
require "addressing/version"

module Addressing
  class Error < StandardError; end

  class UnknownCountryError < Error; end

  class UnknownLocaleError < Error; end
end

if defined?(ActiveSupport.on_load)
  ActiveSupport.on_load(:active_record) do
    require "addressing/model"
    extend Addressing::Model
  end
end

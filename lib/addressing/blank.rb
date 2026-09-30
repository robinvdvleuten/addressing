# frozen_string_literal: true

module Addressing
  # Decides whether a value is blank.
  module Blank
    # Matches a value that holds nothing but whitespace, Unicode included.
    PATTERN = /\A[[:space:]]*\z/
    private_constant :PATTERN

    # Whether the value is blank. Follows ActiveSupport's blank?, and uses it
    # when it is loaded.
    def self.blank?(value)
      return value.blank? if value.respond_to?(:blank?)

      case value
      when String then blank_string?(value)
      when nil, false then true
      else value.respond_to?(:empty?) && value.empty?
      end
    end

    def self.blank_string?(value)
      PATTERN.match?(value)
    rescue Encoding::CompatibilityError
      # The value has an encoding that is not compatible with ASCII.
      Regexp.new(PATTERN.source.encode(value.encoding), PATTERN.options | Regexp::FIXEDENCODING).match?(value)
    end
    private_class_method :blank_string?
  end

  private_constant :Blank
end

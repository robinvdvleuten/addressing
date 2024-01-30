# frozen_string_literal: true

module Addressing
  class Enum
    class << self
      @@values = {}

      # Gets all available values.
      def all
        if !@@values.key?(name)
          @@values[name] = constants.map { |constant| [constant, const_get(constant)] }.to_h
        end

        @@values[name]
      end

      # Gets the key of the provided value.
      def key(value)
        all.key(value)
      end

      # Checks whether the provided value is defined.
      def exists?(value)
        all.has_value?(value)
      end

      # Asserts that the provided value is defined.
      def assert_exists(value)
        raise ArgumentError, "#{value} is not a valid #{name} value." unless exists?(value)
      end

      # Asserts that all provided values are defined.
      def assert_all_exist(values)
        values.each { |value| assert_exists(value.to_s) }
      end
    end
  end

  private_constant :Enum
end

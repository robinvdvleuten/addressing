# frozen_string_literal: true

require_relative "test_helper"

class PostalCodePatternDataTest < Minitest::Test
  def test_every_postal_code_pattern_compiles_as_is
    patterns = Addressing::AddressFormat.all.to_h { |country_code, address_format| [country_code, address_format.postal_code_pattern] }

    Dir[File.expand_path("../data/subdivision/*.json", __dir__)].each do |filename|
      JSON.parse(File.read(filename))["subdivisions"].each do |id, definition|
        patterns["#{File.basename(filename, ".json")} #{id}"] = definition["postal_code_pattern"]
      end
    end
    patterns.compact!

    refute_empty patterns
    patterns.each do |source, pattern|
      # An escaped backslash would need unescaping before it could be used.
      refute_includes pattern, "\\\\", source
      assert_instance_of Regexp, Regexp.new(pattern, "i"), source
    end
  end
end

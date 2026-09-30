# frozen_string_literal: true

require_relative "test_helper"

class SubdivisionDataTest < Minitest::Test
  def setup
    Addressing::Subdivision.instance_variable_set(:@definitions, nil)
    Addressing::Subdivision.instance_variable_set(:@parents, nil)
  end

  def teardown
    Addressing::Subdivision.instance_variable_set(:@definitions, nil)
    Addressing::Subdivision.instance_variable_set(:@parents, nil)
  end

  def test_all_returns_every_subdivision_in_the_data_files
    data_files = Dir[File.expand_path("../data/subdivision/*.json", __dir__)].map do |filename|
      definitions = JSON.parse(File.read(filename, encoding: "UTF-8"))
      {
        name: File.basename(filename),
        parents: definitions["parents"] || [definitions["country_code"]],
        size: definitions["subdivisions"].size
      }
    end

    refute_empty data_files

    # Groups higher up are loaded first, so their definitions are cached
    # before the groups below them are loaded.
    data_files.sort_by { |data_file| data_file[:parents].size }.each do |data_file|
      assert_equal data_file[:size], Addressing::Subdivision.all(data_file[:parents]).size, data_file[:name]
    end
  end

  def test_chilean_localities_without_parent_flag
    Addressing::Subdivision.all(["CL"])

    assert_equal 21, Addressing::Subdivision.all(["CL", "NB"]).size
    refute Addressing::Subdivision.get("NB", ["CL"]).children?
  end

  def test_lowercase_country_code_in_data_files
    assert_equal Addressing::Subdivision.get("CA", ["US"]).to_h, Addressing::Subdivision.get("CA", ["us"]).to_h
    assert_nil Addressing::Subdivision.get("ca", ["US"])
  end
end

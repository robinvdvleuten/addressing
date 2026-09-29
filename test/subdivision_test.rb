# frozen_string_literal: true

require_relative "test_helper"
require "minitest/mock"

class SubdivisionTest < Minitest::Test
  def setup
    # Definitions are cached per process, drop anything loaded by other tests
    # so that the mocked files below are what gets read.
    Addressing::Subdivision.instance_variable_set(:@definitions, nil)
    Addressing::Subdivision.instance_variable_set(:@parents, nil)

    FakeFS.activate!

    subdivision_path = File.expand_path("../data/subdivision", __dir__)
    FakeFS::FileSystem.clone(subdivision_path)

    mock_definitions("#{subdivision_path}/BR.json") do
      {
        country_code: "BR",
        locale: "pt",
        subdivisions: {
          SC: {
            code: "SC",
            name: "Santa Catarina",
            postal_code_pattern: "8[89]",
            has_children: true
          },
          SP: {
            code: "SP",
            name: "São Paulo",
            postal_code_pattern: "[01][1-9]",
            has_children: true
          }
        }
      }
    end

    mock_definitions("#{subdivision_path}/BR-SC.json") do
      {
        country_code: "BR",
        parents: ["BR", "SC"],
        locale: "pt",
        subdivisions: {
          "Abelardo Luz": {}
        }
      }
    end

    mock_definitions("#{subdivision_path}/BR-SP.json") do
      {
        country_code: "BR",
        parents: ["BR", "SP"],
        locale: "pt",
        subdivisions: {
          Anhumas: {}
        }
      }
    end

    # Malformed definitions, expected to be ignored.
    mock_definitions("#{subdivision_path}/US.json") do
      {country_code: "US"}
    end
    File.write("#{subdivision_path}/CA.json", "{invalid json")
  end

  def test_get
    subdivision = Addressing::Subdivision.get("SC", ["BR"])
    subdivision_child = Addressing::Subdivision.get("Abelardo Luz", ["BR", "SC"])

    assert_instance_of Addressing::Subdivision, subdivision
    assert_nil subdivision.parent
    assert_equal "BR", subdivision.country_code
    assert_equal "SC", subdivision.id
    assert_equal "pt", subdivision.locale
    assert_equal "SC", subdivision.code
    assert_equal "Santa Catarina", subdivision.name
    assert_equal "8[89]", subdivision.postal_code_pattern

    children = subdivision.children
    assert_same_elements subdivision_child.to_h, children["Abelardo Luz"].to_h

    assert_instance_of Addressing::Subdivision, subdivision_child
    assert_equal "Abelardo Luz", subdivision_child.id
    assert_equal "Abelardo Luz", subdivision_child.code
    assert_equal "Abelardo Luz", subdivision_child.name

    # subdivision contains the loaded children while parent does not, so they can't be compared directly.
    parent = subdivision_child.parent
    assert_instance_of Addressing::Subdivision, parent
    assert_equal subdivision.code, parent.code
  end

  def test_get_invalid_subdivision
    assert_nil Addressing::Subdivision.get("FAKE", ["BR"])
  end

  def test_malformed_definitions
    # Valid JSON without a "subdivisions" key.
    assert_nil Addressing::Subdivision.get("AL", ["US"])
    assert_empty Addressing::Subdivision.all(["US"])
    assert_empty Addressing::Subdivision.list(["US"])

    # Invalid JSON.
    assert_nil Addressing::Subdivision.get("AB", ["CA"])
    assert_empty Addressing::Subdivision.all(["CA"])
    assert_empty Addressing::Subdivision.list(["CA"])
  end

  def test_all
    subdivisions = Addressing::Subdivision.all(["RS"])
    assert_empty subdivisions

    subdivisions = Addressing::Subdivision.all(["BR"])
    assert_equal 2, subdivisions.length
    assert subdivisions.key?("SC")
    assert subdivisions.key?("SP")
    assert_equal "SC", subdivisions["SC"].code
    assert_equal "SP", subdivisions["SP"].code

    subdivisions = Addressing::Subdivision.all(["BR", "SC"])
    assert_equal 1, subdivisions.length
    assert subdivisions.key?("Abelardo Luz")
    assert_equal "Abelardo Luz", subdivisions["Abelardo Luz"].code
  end

  def test_list
    list = Addressing::Subdivision.list(["RS"])
    assert_empty list

    list = Addressing::Subdivision.list(["BR"])
    assert_equal({"SC" => "Santa Catarina", "SP" => "São Paulo"}, list)

    list = Addressing::Subdivision.list(["BR", "SC"])
    assert_equal({"Abelardo Luz" => "Abelardo Luz"}, list)

    # The local names default to the latin ones.
    list = Addressing::Subdivision.list(["BR"], "pt")
    assert_equal({"SC" => "Santa Catarina", "SP" => "São Paulo"}, list)
  end

  def test_all_without_parent_flag_as_first_call
    mock_chile_definitions

    assert_equal 2, Addressing::Subdivision.all(["CL", "NB"]).size
  end

  def test_all_without_parent_flag_after_loading_parent
    mock_chile_definitions

    Addressing::Subdivision.all(["CL"])

    assert_equal 2, Addressing::Subdivision.all(["CL", "NB"]).size
  end

  def test_children_without_parent_flag
    mock_chile_definitions

    refute Addressing::Subdivision.get("NB", ["CL"]).children?
  end

  def test_lowercase_country_code
    with_case_sensitive_file_system do
      subdivision = Addressing::Subdivision.get("SC", ["br"])

      refute_nil subdivision
      assert_equal Addressing::Subdivision.get("SC", ["BR"]).to_h.except(:children), subdivision.to_h.except(:children)
      refute_nil subdivision.children["Abelardo Luz"]
      assert_equal({"SC" => "Santa Catarina", "SP" => "São Paulo"}, Addressing::Subdivision.list(["br"]))
      assert_equal ["Abelardo Luz"], Addressing::Subdivision.all(["br", "SC"]).keys
    end
  end

  def test_lowercase_subdivision_id
    assert_nil Addressing::Subdivision.get("sc", ["BR"])
    assert_empty Addressing::Subdivision.all(["BR", "sc"])
  end

  def test_get_keeps_cached_definitions_unchanged
    subdivision_path = File.expand_path("../data/subdivision", __dir__)
    mock_definitions("#{subdivision_path}/BR-SC.json") do
      {
        country_code: "BR",
        parents: ["BR", "SC"],
        locale: "pt",
        subdivisions: {
          "Abelardo Luz": {has_children: true}
        }
      }
    end
    mock_definitions("#{subdivision_path}/BR--ca6775b8b8c6e4eda90645d99469ed2fff7f38b0.json") do
      {
        country_code: "BR",
        parents: ["BR", "SC", "Abelardo Luz"],
        locale: "pt",
        subdivisions: {
          Centro: {}
        }
      }
    end

    subdivision = Addressing::Subdivision.get("Abelardo Luz", ["BR", "SC"])
    refute_nil subdivision.parent
    assert subdivision.children?

    definitions = Addressing::Subdivision.instance_variable_get(:@definitions)
    refute definitions["BR"].key?("parents")
    assert_equal ["BR", "SC"], definitions["BR-SC"]["parents"]
    definitions.each_value do |group|
      group["subdivisions"].each_value do |definition|
        refute definition.key?("parent")
        refute definition.key?("children")
        refute definition.key?("parents")
      end
    end
  end

  def test_parents_argument_unchanged
    parents = ["br", "SC"]
    Addressing::Subdivision.get("Abelardo Luz", parents)
    Addressing::Subdivision.all(parents)
    Addressing::Subdivision.list(parents)
    assert_equal ["br", "SC"], parents

    frozen_parents = ["BR", "SC"].freeze
    refute_nil Addressing::Subdivision.get("Abelardo Luz", frozen_parents)
    refute_empty Addressing::Subdivision.all(frozen_parents)
    refute_empty Addressing::Subdivision.list(frozen_parents)
  end

  def test_missing_property
    assert_raises(ArgumentError) do
      Addressing::Subdivision.new(country_code: "US")
    end
  end

  def test_valid
    parent = {}
    children = [{}, {}]

    subdivision = Addressing::Subdivision.new(
      parent: parent,
      country_code: "US",
      id: "CA",
      locale: "en",
      code: "CA",
      local_code: "CA!",
      name: "California",
      local_name: "California!",
      postal_code_pattern: "9[0-5]|96[01]",
      children: children
    )

    assert_equal parent, subdivision.parent
    assert_equal "US", subdivision.country_code
    assert_equal "CA", subdivision.id
    assert_equal "en", subdivision.locale
    assert_equal "CA", subdivision.code
    assert_equal "CA!", subdivision.local_code
    assert_equal "California", subdivision.name
    assert_equal "California!", subdivision.local_name
    assert_equal "9[0-5]|96[01]", subdivision.postal_code_pattern
    assert_equal children, subdivision.children
    assert subdivision.children?
  end

  def teardown
    FakeFS.deactivate!
    Addressing::Subdivision.instance_variable_set(:@definitions, nil)
    Addressing::Subdivision.instance_variable_set(:@parents, nil)
  end

  private

  # The file system that runs the tests can ignore case, so only a file whose
  # name matches in case is taken to exist.
  def with_case_sensitive_file_system(&)
    exact_case_exist = ->(path) { File.directory?(File.dirname(path)) && Dir.children(File.dirname(path)).include?(File.basename(path)) }
    File.stub(:exist?, exact_case_exist, &)
  end

  # The parent definition lacks the has_children flag, while the file with its
  # children exists.
  def mock_chile_definitions
    subdivision_path = File.expand_path("../data/subdivision", __dir__)

    mock_definitions("#{subdivision_path}/CL.json") do
      {
        country_code: "CL",
        subdivisions: {
          NB: {name: "Ñuble"}
        }
      }
    end

    mock_definitions("#{subdivision_path}/CL-NB.json") do
      {
        country_code: "CL",
        parents: ["CL", "NB"],
        subdivisions: {
          Coihueco: {},
          Yungay: {}
        }
      }
    end
  end

  def mock_definitions(filename, &block)
    FileUtils.mkdir_p(File.dirname(filename))
    File.write(filename, JSON.dump(block.call))
  end
end

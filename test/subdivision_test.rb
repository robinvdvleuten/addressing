# frozen_string_literal: true

require_relative "test_helper"

class SubdivisionTest < Minitest::Test
  def setup
    FakeFS.activate!

    FakeFS::FileSystem.clone(File.expand_path("../../data/address_formats.dump", __FILE__))

    subdivision_path = File.expand_path("../../data/subdivision", __FILE__)
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
  end

  private

  def mock_definitions(filename, &block)
    FileUtils.mkdir_p(File.dirname(filename))
    File.write(filename, JSON.dump(block.call))
  end
end

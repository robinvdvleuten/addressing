# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"

class SubdivisionTest < Minitest::Test
  include FixtureData

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
    assert_equal subdivision_child.to_h.except(:parent), children["Abelardo Luz"].to_h.except(:parent)
    assert_equal subdivision_child.parent.to_h.except(:children), children["Abelardo Luz"].parent.to_h.except(:children)

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

    # Valid JSON that is not an object.
    assert_nil Addressing::Subdivision.get("AG", ["MX"])
    assert_empty Addressing::Subdivision.all(["MX"])
  end

  def test_invalid_json_raises
    # The data files are never edited by hand, so this means a sync broke.
    assert_raises(JSON::ParserError) { Addressing::Subdivision.get("AB", ["CA"]) }
  end

  def test_all
    subdivisions = Addressing::Subdivision.all(["RS"])
    assert_empty subdivisions

    subdivisions = Addressing::Subdivision.all(["BR"])
    assert_equal ["CE", "SC", "SP"], subdivisions.keys
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
    assert_equal({"CE" => "Ceará", "SC" => "Santa Catarina", "SP" => "São Paulo"}, list)

    list = Addressing::Subdivision.list(["BR", "SC"])
    assert_equal({"Abelardo Luz" => "Abelardo Luz"}, list)

    # The local names default to the latin ones.
    list = Addressing::Subdivision.list(["BR"], "pt")
    assert_equal({"CE" => "Ceará", "SC" => "Santa Catarina", "SP" => "São Paulo"}, list)
  end

  def test_all_without_parent_flag_as_first_call
    assert_equal 2, Addressing::Subdivision.all(["CL", "NB"]).size
  end

  def test_all_without_parent_flag_after_loading_parent
    Addressing::Subdivision.all(["CL"])

    assert_equal 2, Addressing::Subdivision.all(["CL", "NB"]).size
  end

  def test_children_without_parent_flag
    refute Addressing::Subdivision.get("NB", ["CL"]).children?
  end

  def test_lowercase_country_code
    subdivision = Addressing::Subdivision.get("SC", ["br"])

    refute_nil subdivision
    assert_equal Addressing::Subdivision.get("SC", ["BR"]).to_h.except(:children), subdivision.to_h.except(:children)
    refute_nil subdivision.children["Abelardo Luz"]
    assert_equal({"CE" => "Ceará", "SC" => "Santa Catarina", "SP" => "São Paulo"}, Addressing::Subdivision.list(["br"]))
    assert_equal ["Abelardo Luz"], Addressing::Subdivision.all(["br", "SC"]).keys
  end

  def test_lowercase_subdivision_id
    assert_nil Addressing::Subdivision.get("sc", ["BR"])
    assert_empty Addressing::Subdivision.all(["BR", "sc"])
  end

  def test_get_keeps_cached_definitions_unchanged
    subdivision = Addressing::Subdivision.get("Centro", ["BR", "SP", "Anhumas"])
    refute_nil subdivision.parent.parent
    assert Addressing::Subdivision.get("Anhumas", ["BR", "SP"]).children?

    groups = [["BR"], ["BR", "SP"], ["BR", "SP", "Anhumas"]].to_h do |parents|
      [parents, Addressing.data_source.fetch("subdivision/#{Addressing::Subdivision.group_key(parents)}")]
    end
    refute groups[["BR"]].key?("parents")
    assert_equal ["BR", "SP"], groups[["BR", "SP"]]["parents"]
    groups.each_value do |group|
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

  def test_chain
    chain = Addressing::Subdivision.chain("BR", ["CE", "Fortaleza"])

    assert_equal ["CE", "Fortaleza"], chain.subdivisions.map(&:id)
    assert_nil chain.unmatched_level
  end

  def test_chain_with_unmatched_level
    chain = Addressing::Subdivision.chain("BR", ["CE", "Nowhere"])
    assert_equal ["CE"], chain.subdivisions.map(&:id)
    assert_equal 1, chain.unmatched_level

    chain = Addressing::Subdivision.chain("BR", ["XX", "Fortaleza"])
    assert_empty chain.subdivisions
    assert_equal 0, chain.unmatched_level

    chain = Addressing::Subdivision.chain("BR", [1])
    assert_empty chain.subdivisions
    assert_equal 0, chain.unmatched_level
  end

  def test_chain_stops_at_empty_level
    [["CE", ""], ["CE", nil], ["CE", "  "], ["CE", "", "Fortaleza"]].each do |values|
      chain = Addressing::Subdivision.chain("BR", values)
      assert_equal ["CE"], chain.subdivisions.map(&:id), values.inspect
      assert_nil chain.unmatched_level, values.inspect
    end

    chain = Addressing::Subdivision.chain("BR", ["", "Fortaleza"])
    assert_empty chain.subdivisions
    assert_nil chain.unmatched_level
  end

  def test_chain_stops_at_subdivision_without_children
    chain = Addressing::Subdivision.chain("BR", ["CE", "Fortaleza", "Centro"])

    assert_equal ["CE", "Fortaleza"], chain.subdivisions.map(&:id)
    assert_nil chain.unmatched_level
  end

  def test_chain_for_country_without_predefined_subdivisions
    chain = Addressing::Subdivision.chain("ZZ", ["Somewhere", "Else"])

    assert_empty chain.subdivisions
    assert_nil chain.unmatched_level
  end

  def test_chain_with_lowercase_country_code
    expected = Addressing::Subdivision.chain("BR", ["CE"])
    chain = Addressing::Subdivision.chain("br", ["CE"])

    assert_equal expected.subdivisions.map { |s| s.to_h.except(:children) }, chain.subdivisions.map { |s| s.to_h.except(:children) }
    assert_equal ["CE"], chain.subdivisions.map(&:id)
    assert_nil chain.unmatched_level
  end

  def test_chain_values_argument_unchanged
    values = ["CE", "Fortaleza"]
    Addressing::Subdivision.chain("BR", values)
    assert_equal ["CE", "Fortaleza"], values

    frozen_values = ["CE", "Fortaleza"].freeze
    assert_equal 2, Addressing::Subdivision.chain("BR", frozen_values).subdivisions.size
  end

  def test_children_behave_like_all
    children = Addressing::Subdivision.get("CE", ["BR"]).children
    all = Addressing::Subdivision.all(["BR", "CE"])

    assert_equal all.size, children.size
    assert_equal ["Fortaleza"], children.keys
    assert_equal ["Fortaleza"], children.map { |id, subdivision| subdivision.id }
    assert_equal({"Fortaleza" => "Fortaleza"}, children.each_with_object({}) { |(id, subdivision), h| h[id] = subdivision.name })
    assert_equal "Fortaleza", children["Fortaleza"].id
    assert children.any?
    refute children.empty?
    assert children.include?("Fortaleza")
    assert_equal "Fortaleza", children.fetch("Fortaleza").id
    assert_equal ["Fortaleza"], children.select { |id, subdivision| subdivision.name == "Fortaleza" }.keys
    assert_empty children.reject { |id, subdivision| subdivision.name == "Fortaleza" }

    leaf_children = Addressing::Subdivision.get("Fortaleza", ["BR", "CE"]).children
    assert_equal 0, leaf_children.size
    assert_empty leaf_children.keys
  end

  def test_children_load_on_first_access
    children = Addressing::Subdivision.get("CE", ["BR"]).children

    # Only a lazy load reads the children from the data source that is
    # current when they are first accessed.
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "subdivision"))
      File.write(File.join(dir, "subdivision", "BR-CE.json"), JSON.dump({
        country_code: "BR",
        parents: ["BR", "CE"],
        subdivisions: {Fortaleza: [], Sobral: []}
      }))

      with_data_source(Addressing::DataSource.new(dir)) do
        assert_equal ["Fortaleza", "Sobral"], children.keys
      end
    end
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
end

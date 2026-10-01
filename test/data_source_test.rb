# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"

class DataSourceTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @source = Addressing::DataSource.new(@dir)
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def test_fetch_parses_the_dataset
    write("country/en", '{"FR": "France"}')

    assert_equal({"FR" => "France"}, @source.fetch("country/en"))
  end

  def test_fetch_caches_what_the_block_makes_of_the_dataset
    write("country/en", '{"FR": "France"}')
    calls = 0
    process = lambda do |json|
      calls += 1
      json.keys
    end

    assert_equal ["FR"], @source.fetch("country/en", &process)
    write("country/en", '{"DE": "Germany"}')
    assert_equal ["FR"], @source.fetch("country/en", &process)
    assert_equal 1, calls
  end

  def test_fetch_gives_nil_for_a_missing_dataset_and_remembers_it
    assert_nil @source.fetch("subdivision/ZZ") { flunk "block called for a missing dataset" }

    write("subdivision/ZZ", "{}")
    assert_nil @source.fetch("subdivision/ZZ")
  end

  def test_fetch_matches_the_name_in_case
    # Subdivision IDs are case-sensitive, also on a file system that is not.
    write("subdivision/BR-SC", "{}")

    assert_nil @source.fetch("subdivision/BR-sc")
    assert_equal({}, @source.fetch("subdivision/BR-SC"))
  end

  def test_fetch_raises_for_a_malformed_dataset
    write("countries", "{")

    assert_raises(JSON::ParserError) { @source.fetch("countries") }

    # Nothing was cached, a fixed file is read on the next fetch.
    write("countries", "{}")
    assert_equal({}, @source.fetch("countries"))
  end

  def test_fetch_reads_utf8_whatever_the_default_external_encoding
    write("country/es", '{"ES": "España"}')
    default_external = Encoding.default_external
    set_default_external(Encoding::US_ASCII)

    name = @source.fetch("country/es")["ES"]

    assert_equal "España", name
    assert_equal Encoding::UTF_8, name.encoding
  ensure
    set_default_external(default_external)
  end

  def test_names_lists_the_datasets_in_a_directory
    write("country/fr", "{}")
    write("country/en", "{}")
    write("countries", "{}")

    assert_equal ["en", "fr"], @source.names("country")
    assert_equal [], @source.names("subdivision")
  end

  private

  # Ruby warns when the default external encoding changes.
  def set_default_external(encoding)
    verbose, $VERBOSE = $VERBOSE, nil
    Encoding.default_external = encoding
  ensure
    $VERBOSE = verbose
  end

  def write(name, content)
    filename = File.join(@dir, "#{name}.json")
    FileUtils.mkdir_p(File.dirname(filename))
    File.write(filename, content)
  end
end

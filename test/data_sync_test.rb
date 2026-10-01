# frozen_string_literal: true

require_relative "test_helper"
require_relative "../tasks/data_sync"
require "tmpdir"

class DataSyncTest < Minitest::Test
  # What the PHP scripts print for a checkout, by the class they read.
  EXTRACTED = {
    "CountryRepository" => {"BR" => ["BRA", "076", "BRL"], "AQ" => ["ATA", "010", nil]},
    "Locale" => {"aliases" => {"zh-TW" => "zh-Hant-TW"}, "parents" => {"en-150" => "en-001"}},
    "AddressFormatRepository" => {
      "BR" => {
        "format" => "%givenName %familyName\n%addressLine1\n%dependentLocality\n%locality-%administrativeArea\n%postalCode",
        "required_fields" => ["addressLine1", "locality", "administrativeArea", "postalCode"],
        "uppercase_fields" => ["locality", "administrativeArea"],
        "subdivision_data_fields" => ["administrativeArea", "locality"],
        "postal_code_pattern" => "\\d{5}-?\\d{3}"
      }
    }
  }

  def setup
    @upstream_dir = Dir.mktmpdir
    @data_dir = Dir.mktmpdir
    @scripts = []

    write_upstream("resources/country/en.json", "{\n\t\"BR\": \"Brazil\"\n}\n")
    write_upstream("resources/country/pt.json", "{\n\t\"BR\": \"Brasil\"\n}\n")
    write_upstream("resources/subdivision/BR.json", "{\n\t\"country_code\": \"BR\",\n\t\"subdivisions\": {\n\t\t\"CE\": {\n\t\t\t\"has_children\": true\n\t\t}\n\t}\n}\n")
    write_upstream("resources/subdivision/BR-CE.json", "{\n\t\"country_code\": \"BR\",\n\t\"parents\": [\"BR\", \"CE\"],\n\t\"subdivisions\": {\n\t\t\"Fortaleza\": []\n\t}\n}\n")
    # Upstream names deeper groups after a Tiger hash.
    write_upstream("resources/subdivision/BR--7a2f.json", "{\n\t\"country_code\": \"BR\",\n\t\"parents\": [\"BR\", \"CE\", \"Fortaleza\"],\n\t\"subdivisions\": {\n\t\t\"Centro\": []\n\t}\n}\n")
  end

  def teardown
    FileUtils.remove_entry(@upstream_dir)
    FileUtils.remove_entry(@data_dir)
  end

  def test_copies_country_files_unchanged
    sync

    assert_equal ["en.json", "pt.json"], Dir.children(File.join(@data_dir, "country")).sort
    assert_equal upstream("resources/country/pt.json"), data("country/pt.json")
  end

  def test_copies_subdivision_files_unchanged_under_their_group_key
    sync

    deep_group_key = Addressing::Subdivision.group_key(["BR", "CE", "Fortaleza"])

    assert_equal ["BR-CE.json", "BR.json", "#{deep_group_key}.json"].sort, Dir.children(File.join(@data_dir, "subdivision")).sort
    assert_equal upstream("resources/subdivision/BR.json"), data("subdivision/BR.json")
    assert_equal upstream("resources/subdivision/BR-CE.json"), data("subdivision/BR-CE.json")
    assert_equal upstream("resources/subdivision/BR--7a2f.json"), data("subdivision/#{deep_group_key}.json")
  end

  def test_replaces_the_previous_data_files
    write_data("subdivision/XX.json", "{}")
    write_data("country/tlh.json", "{}")

    sync

    refute File.exist?(File.join(@data_dir, "subdivision/XX.json"))
    refute File.exist?(File.join(@data_dir, "country/tlh.json"))
  end

  def test_writes_countries_with_named_keys
    sync

    assert_equal({
      "BR" => {"three_letter_code" => "BRA", "numeric_code" => "076", "currency_code" => "BRL"},
      "AQ" => {"three_letter_code" => "ATA", "numeric_code" => "010", "currency_code" => nil}
    }, JSON.parse(data("countries.json")))
  end

  def test_writes_locale_aliases_and_parents
    sync

    assert_equal EXTRACTED["Locale"], JSON.parse(data("locale.json"))
  end

  def test_writes_address_formats_with_snake_case_fields
    sync

    assert_equal [{
      "country_code" => "BR",
      "format" => "%given_name %family_name\n%address_line1\n%dependent_locality\n%locality-%administrative_area\n%postal_code",
      "required_fields" => ["address_line1", "locality", "administrative_area", "postal_code"],
      "uppercase_fields" => ["locality", "administrative_area"],
      "postal_code_pattern" => "\\d{5}-?\\d{3}",
      "subdivision_fields" => ["administrative_area", "locality"]
    }], data("address_formats.json").lines.map { |line| JSON.parse(line) }
  end

  def test_writes_the_upstream_version
    sync(version: "v9.9.9")

    assert_equal "v9.9.9\n", data("UPSTREAM_VERSION")
  end

  def test_php_scripts_read_the_upstream_checkout
    sync

    assert_equal 3, @scripts.size
    assert @scripts.all? { |script| script.include?("require '#{@upstream_dir}/src/") }
  end

  def test_raises_when_php_extracts_nothing
    error = assert_raises(RuntimeError) do
      Addressing::DataSync.new(upstream_dir: @upstream_dir, data_dir: @data_dir, php: ->(_script) { {} }).sync
    end

    assert_equal "Unable to extract base definitions from CountryRepository.php", error.message
  end

  def test_raises_when_two_upstream_files_share_a_group_key
    write_upstream("resources/subdivision/BR-copy.json", upstream("resources/subdivision/BR.json"))

    assert_raises(RuntimeError) { sync }
  end

  def test_underscore
    assert_equal "address_line1", Addressing::DataSync.underscore("addressLine1")
    assert_equal "administrative_area", Addressing::DataSync.underscore("administrativeArea")
    assert_equal "%given_name", Addressing::DataSync.underscore("%givenName")
    assert_equal "organization", Addressing::DataSync.underscore("organization")
  end

  private

  def sync(version: Addressing::DataSync::UPSTREAM_VERSION)
    php = lambda do |script|
      @scripts << script
      EXTRACTED.find { |class_name, _| script.include?("/#{class_name}.php") }&.last
    end

    Addressing::DataSync.new(upstream_dir: @upstream_dir, data_dir: @data_dir, version: version, php: php).sync
  end

  def upstream(path)
    File.read(File.join(@upstream_dir, path), encoding: "UTF-8")
  end

  def data(path)
    File.read(File.join(@data_dir, path), encoding: "UTF-8")
  end

  def write_upstream(path, content)
    write(File.join(@upstream_dir, path), content)
  end

  def write_data(path, content)
    write(File.join(@data_dir, path), content)
  end

  def write(filename, content)
    FileUtils.mkdir_p(File.dirname(filename))
    File.write(filename, content)
  end
end

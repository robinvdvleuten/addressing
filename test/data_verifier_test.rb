# frozen_string_literal: true

require_relative "test_helper"
require_relative "../tasks/data_verifier"
require "tmpdir"

class DataVerifierTest < Minitest::Test
  def setup
    @data_dir = Dir.mktmpdir

    write("country/en.json", {"BR" => "Brazil", "CL" => "Chile"})

    write("subdivision/BR.json", {
      country_code: "BR",
      subdivisions: {
        CE: {name: "Ceará", has_children: true},
        SP: {name: "São Paulo", postal_code_pattern: "[01][1-9]"}
      }
    })
    write("subdivision/BR-CE.json", {
      country_code: "BR",
      parents: ["BR", "CE"],
      subdivisions: {Fortaleza: []}
    })
  end

  def teardown
    FileUtils.remove_entry(@data_dir)
  end

  def test_consistent_data
    assert_empty discrepancies
  end

  def test_real_data_is_readable
    # The real data can hold discrepancies that are waiting for an upstream
    # fix, so only confirm that it can be verified.
    assert_kind_of Array, Addressing::DataVerifier.new.discrepancies
  end

  def test_real_known_discrepancies_are_readable
    known = Addressing::DataVerifier.known_discrepancies

    assert_kind_of Array, known
    assert known.all?(String)
  end

  def test_verify_without_discrepancies
    result = verifier.verify

    assert result.ok?
    assert_empty result.unexpected
    assert_empty result.known
    assert_empty result.resolved
  end

  def test_verify_splits_unexpected_known_and_resolved
    FileUtils.rm(File.join(@data_dir, "subdivision/BR-CE.json"))
    write("country/en.json", {"BR" => "Brazil"})

    missing_children = "subdivision/BR.json (CE): has the has_children flag, but no data file holds its children"
    missing_name = "country/en.json: has no name for country CL"
    fixed = "subdivision/BR-SP.json: holds the children of SP, which has no has_children flag"

    result = verifier.verify(known: [missing_children, fixed])

    refute result.ok?
    assert_equal [missing_name], result.unexpected
    assert_equal [missing_children], result.known
    assert_equal [fixed], result.resolved
  end

  def test_verify_with_known_discrepancies_only
    FileUtils.rm(File.join(@data_dir, "subdivision/BR-CE.json"))

    result = verifier.verify(known: ["subdivision/BR.json (CE): has the has_children flag, but no data file holds its children"])

    assert result.ok?
  end

  def test_verify_fails_on_resolved_discrepancy
    result = verifier.verify(known: ["subdivision/BR-SP.json: holds the children of SP, which has no has_children flag"])

    refute result.ok?
    assert_empty result.unexpected
  end

  def test_known_discrepancies_from_file
    filename = File.join(@data_dir, "known.yml")

    File.write(filename, "- discrepancy: \"country/en.json: has no name for country CL\"\n  upstream: \"https://example.com/1\"\n")
    assert_equal ["country/en.json: has no name for country CL"], Addressing::DataVerifier.known_discrepancies(filename)

    File.write(filename, "# Nothing is known.\n")
    assert_empty Addressing::DataVerifier.known_discrepancies(filename)
  end

  def test_child_file_without_flagged_parent
    write("subdivision/BR-SP.json", {
      country_code: "BR",
      parents: ["BR", "SP"],
      subdivisions: {Campinas: {}}
    })

    assert_equal ["subdivision/BR-SP.json: holds the children of SP, which has no has_children flag"], discrepancies
  end

  def test_child_file_without_parent
    write("subdivision/BR-RJ.json", {
      country_code: "BR",
      parents: ["BR", "RJ"],
      subdivisions: {"Niterói" => {}}
    })

    assert_equal ["subdivision/BR-RJ.json: holds the children of RJ, which does not exist"], discrepancies
  end

  def test_flag_without_child_file
    FileUtils.rm(File.join(@data_dir, "subdivision/BR-CE.json"))

    assert_equal ["subdivision/BR.json (CE): has the has_children flag, but no data file holds its children"], discrepancies
  end

  def test_file_name_that_is_never_read
    FileUtils.mv(File.join(@data_dir, "subdivision/BR-CE.json"), File.join(@data_dir, "subdivision/BR-Ceara.json"))

    assert_equal ["subdivision/BR-Ceara.json: is never read, the file for parents [\"BR\", \"CE\"] must be named BR-CE.json"], discrepancies
  end

  def test_level_below_the_subdivision_fields
    write("subdivision/BR.json", {
      country_code: "BR",
      subdivisions: {CE: {name: "Ceará", has_children: true}}
    })

    assert_equal ["subdivision/BR-CE.json: holds level 2, but the address format of BR has 1 subdivision fields"], discrepancies(subdivision_fields: ["administrative_area"])
  end

  def test_subdivision_fields_without_data_file
    assert_equal ["address_formats.json (CL): has subdivision fields, but the country has no subdivision data file"], discrepancies(formats: {"CL" => ["administrative_area"]})
  end

  def test_invalid_postal_code_pattern
    write("subdivision/BR.json", {
      country_code: "BR",
      subdivisions: {
        CE: {name: "Ceará", has_children: true},
        SP: {name: "São Paulo", postal_code_pattern: "[01"}
      }
    })

    assert_equal 1, discrepancies.size
    assert_match(/\Asubdivision\/BR\.json \(SP\): has an invalid postal code pattern/, discrepancies.first)
  end

  def test_malformed_files
    File.write(File.join(@data_dir, "subdivision/CL.json"), "{invalid json")
    write("subdivision/AR.json", {country_code: "AR"})

    assert_equal [
      "subdivision/CL.json: is not valid JSON",
      "subdivision/AR.json: has no subdivisions"
    ], discrepancies
  end

  def test_countries
    write("country/en.json", {"BR" => "Brazil", "XX" => "Nowhere"})
    write("country/tlh.json", {"BR" => "Brazil", "CL" => "Chile"})

    assert_equal [
      "country: locale pt has no data file",
      "country/en.json: has no name for country CL",
      "country/en.json: names the unknown country XX",
      "country/tlh.json: is not a locale known to Country"
    ], discrepancies(locales: ["en", "pt"])
  end

  def test_address_format_for_unknown_country
    assert_equal ["address_formats.json (XX): is for an unknown country"], discrepancies(formats: {"XX" => []})
  end

  private

  def discrepancies(**options)
    verifier(**options).discrepancies.map(&:to_s)
  end

  def verifier(subdivision_fields: ["administrative_area", "locality"], formats: {}, locales: ["en"])
    formats = {"BR" => subdivision_fields}.merge(formats)
    address_formats = formats.to_h do |country_code, fields|
      [country_code, Addressing::AddressFormat.new(country_code: country_code, format: "%locality", subdivision_fields: fields)]
    end

    Addressing::DataVerifier.new(
      data_dir: @data_dir,
      address_formats: address_formats,
      country_codes: ["BR", "CL"],
      locales: locales
    )
  end

  def write(path, content)
    filename = File.join(@data_dir, path)

    FileUtils.mkdir_p(File.dirname(filename))
    File.write(filename, JSON.dump(content))
  end
end

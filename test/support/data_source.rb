# frozen_string_literal: true

require "tmpdir"

FIXTURE_DATA_DIR = File.expand_path("../fixtures/data", __dir__)

class Minitest::Test
  # Reads the reference data from the provided data source while the block runs.
  def with_data_source(source)
    previous = Addressing.data_source
    Addressing.data_source = source
    yield
  ensure
    Addressing.data_source = previous
  end

  # Reads the fixture data while the block runs, with one address format:
  # the one for the fixture country XA, built from the provided definition.
  def with_address_format(format:, **definition, &)
    Dir.mktmpdir do |dir|
      FileUtils.cp_r(File.join(FIXTURE_DATA_DIR, "."), dir)
      File.write(File.join(dir, "address_formats.json"), JSON.dump("XA" => {country_code: "XA", format: format, **definition}))

      with_data_source(Addressing::DataSource.new(dir), &)
    end
  end
end

# Runs each test of the class against the fixture data in test/fixtures/data,
# with an empty cache.
module FixtureData
  def run(...)
    with_data_source(Addressing::DataSource.new(FIXTURE_DATA_DIR)) { super }
  end
end

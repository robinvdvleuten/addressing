# frozen_string_literal: true

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
end

# Runs each test of the class against the fixture data in test/fixtures/data,
# with an empty cache.
module FixtureData
  def run(...)
    with_data_source(Addressing::DataSource.new(FIXTURE_DATA_DIR)) { super }
  end
end

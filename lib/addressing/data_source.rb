# frozen_string_literal: true

module Addressing
  class << self
    # The data source that the reference data is read from.
    #
    # @api private
    attr_writer :data_source

    # @api private
    # @return [DataSource]
    def data_source
      @data_source ||= DataSource.new(DataSource::DEFAULT_DIR)
    end
  end

  # Reads the reference data: the JSON files that the data sync writes.
  #
  # Each instance has its own cache, so a new instance reads the files again.
  #
  # @api private
  class DataSource
    # The data directory that ships with the gem.
    DEFAULT_DIR = File.expand_path("../../data", __dir__)

    def initialize(dir)
      @dir = dir
      @cache = {}
    end

    # Gets the dataset with the provided name.
    #
    # The parsed JSON is passed to the block, and the result of the block is
    # cached, so each dataset is read and processed once per data source.
    # A missing dataset gives nil, which is cached as well. Malformed JSON
    # raises, because the data files are never edited by hand.
    #
    # @param name [String] Path relative to the data directory, without extension (e.g. "country/en")
    # @yieldparam json [Hash, Array] The parsed dataset
    # @return [Object, nil] The result of the block, or the parsed dataset without a block
    # @raise [JSON::ParserError] if the dataset is malformed
    def fetch(name)
      return @cache[name] if @cache.key?(name)

      filename = File.join(@dir, "#{name}.json")
      return @cache[name] = nil unless File.exist?(filename)

      json = JSON.parse(File.read(filename, encoding: "UTF-8"))
      @cache[name] = block_given? ? yield(json) : json
    end

    # Gets the names of the datasets in a directory, without the directory.
    #
    # @param dir [String] Directory relative to the data directory (e.g. "country")
    # @return [Array<String>] Sorted names (e.g. ["af", "ak", ...])
    def names(dir)
      Dir[File.join(@dir, dir, "*.json")].map { |filename| File.basename(filename, ".json") }.sort
    end
  end
end

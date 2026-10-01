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

      dir, basename = File.split(name)
      return @cache[name] = nil unless filenames(dir).include?("#{basename}.json")

      json = JSON.parse(File.read(File.join(@dir, "#{name}.json"), encoding: "UTF-8"))
      @cache[name] = block_given? ? yield(json) : json
    end

    # Gets the names of the datasets in a directory, without the directory.
    #
    # @param dir [String] Directory relative to the data directory (e.g. "country")
    # @return [Array<String>] Sorted names (e.g. ["af", "ak", ...])
    def names(dir)
      filenames(dir).filter_map { |filename| File.basename(filename, ".json") if filename.end_with?(".json") }.sort
    end

    private

    # Gets the file names in a directory of the data directory.
    #
    # A dataset exists only when its name matches a file name exactly, so
    # that a lookup gives the same result on a case-insensitive file system.
    # The listing is cached like the datasets, so a file added later is not
    # seen by this instance.
    def filenames(dir)
      (@filenames ||= {})[dir] ||= begin
        path = File.join(@dir, dir)
        Dir.exist?(path) ? Dir.children(path).to_set : Set.new
      end
    end
  end
end

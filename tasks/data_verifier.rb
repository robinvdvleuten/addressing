# frozen_string_literal: true

require "json"
require "yaml"
require "addressing"

module Addressing
  # Finds discrepancies in the data files that are synced from upstream.
  #
  # Upstream maintains its subdivisions and address formats by hand, so
  # nothing guarantees that the files agree with each other. A discrepancy
  # is fixed upstream and arrives with the next sync, the data files are
  # never edited here.
  class DataVerifier
    Discrepancy = Struct.new(:source, :message) do
      def to_s
        "#{source}: #{message}"
      end
    end

    # The outcome of a verification against the known discrepancies.
    Result = Struct.new(:unexpected, :known, :resolved) do
      def ok?
        unexpected.empty? && resolved.empty?
      end
    end

    DEFAULT_DATA_DIR = File.expand_path("../data", __dir__)
    KNOWN_DISCREPANCIES = File.expand_path("known_discrepancies.yml", __dir__)

    # Reads the discrepancies that are reported upstream and wait for a fix.
    #
    # @return [Array<String>]
    def self.known_discrepancies(filename = KNOWN_DISCREPANCIES)
      (YAML.safe_load_file(filename) || []).map { |entry| entry.fetch("discrepancy") }
    end

    # @param data_dir [String] Directory that holds the country and subdivision data
    # @param address_formats [Hash<String, AddressFormat>] Address formats by country code
    # @param country_codes [Array<String>] Country codes known to Country
    # @param locales [Array<String>] Locales known to Country
    def initialize(data_dir: DEFAULT_DATA_DIR, address_formats: AddressFormat.all, country_codes: Country.send(:base_definitions).keys, locales: Country.singleton_class::AVAILABLE_LOCALES)
      @data_dir = data_dir
      @address_formats = address_formats
      @country_codes = country_codes
      @locales = locales
    end

    # @return [Array<Discrepancy>] Empty when the data is consistent
    def discrepancies
      @discrepancies = []

      verify_countries
      verify_address_formats
      verify_subdivisions

      @discrepancies
    end

    # Splits the discrepancies by what has to happen with them.
    #
    # A discrepancy that is not known is unexpected. A known discrepancy that
    # no longer occurs is resolved, its entry has to be removed so that the
    # list does not hide the same discrepancy when it comes back.
    #
    # @param known [Array<String>] Discrepancies that wait for an upstream fix
    # @return [Result]
    def verify(known: [])
      found = discrepancies.map(&:to_s)

      Result.new(found - known, found & known, known - found)
    end

    private

    def verify_countries
      files = read_files("country")

      (@locales - files.keys).each { |locale| report("country", "locale #{locale} has no data file") }

      files.each do |locale, names|
        source = "country/#{locale}.json"

        report(source, "is not a locale known to Country") unless @locales.include?(locale)

        (@country_codes - names.keys).each { |code| report(source, "has no name for country #{code}") }
        (names.keys - @country_codes).each { |code| report(source, "names the unknown country #{code}") }
      end
    end

    def verify_address_formats
      @address_formats.each do |country_code, address_format|
        source = "address_formats.json (#{country_code})"

        report(source, "is for an unknown country") unless @country_codes.include?(country_code)
        verify_pattern(source, address_format.postal_code_pattern)
      end
    end

    def verify_subdivisions
      files = read_files("subdivision")
      # The files are found through the parents they declare and not through
      # their names, so that a wrong name is reported and does not hide them.
      groups = files.each_value.to_h { |definitions| [parents_of(definitions), definitions] }

      files.each do |name, definitions|
        source = "subdivision/#{name}.json"

        unless definitions["subdivisions"].is_a?(Hash)
          report(source, "has no subdivisions")
          next
        end

        parents = parents_of(definitions)

        verify_group_name(source, name, parents)
        verify_levels(source, parents)
        verify_parent(source, parents, groups)

        definitions["subdivisions"].each do |id, definition|
          # Upstream writes a definition without keys as an empty JSON array.
          definition = {} unless definition.is_a?(Hash)

          verify_pattern("#{source} (#{id})", definition["postal_code_pattern"])

          if definition["has_children"] && !groups.key?(parents + [id])
            report("#{source} (#{id})", "has the has_children flag, but no data file holds its children")
          end
        end
      end

      @address_formats.each do |country_code, address_format|
        next if address_format.subdivision_fields.empty? || groups.key?([country_code])

        report("address_formats.json (#{country_code})", "has subdivision fields, but the country has no subdivision data file")
      end
    end

    def verify_group_name(source, name, parents)
      # The naming rule has one home, which is the one that reads the files.
      expected = Subdivision.group_key(parents)

      report(source, "is never read, the file for parents #{parents.inspect} must be named #{expected}.json") unless name == expected
    end

    def verify_levels(source, parents)
      subdivision_fields = @address_formats[parents[0]]&.subdivision_fields || []

      if parents.size > subdivision_fields.size
        report(source, "holds level #{parents.size}, but the address format of #{parents[0]} has #{subdivision_fields.size} subdivision fields")
      end
    end

    def verify_parent(source, parents, groups)
      return if parents.size == 1

      parent_id = parents[-1]
      parent = groups.dig(parents[0...-1], "subdivisions", parent_id)

      if parent.nil?
        report(source, "holds the children of #{parent_id}, which does not exist")
      elsif !parent["has_children"]
        report(source, "holds the children of #{parent_id}, which has no has_children flag")
      end
    end

    def verify_pattern(source, pattern)
      Regexp.new(pattern) if pattern
    rescue RegexpError => e
      report(source, "has an invalid postal code pattern (#{e.message})")
    end

    # The 'parents' key is omitted when it contains just the country code.
    def parents_of(definitions)
      definitions["parents"] || [definitions["country_code"]]
    end

    def read_files(dataset)
      Dir[File.join(@data_dir, dataset, "*.json")].sort.each_with_object({}) do |filename, files|
        name = File.basename(filename, ".json")
        content = JSON.parse(File.read(filename, encoding: "UTF-8"))

        if content.is_a?(Hash)
          files[name] = content
        else
          report("#{dataset}/#{name}.json", "does not hold a JSON object")
        end
      rescue JSON::ParserError
        report("#{dataset}/#{name}.json", "is not valid JSON")
      end
    end

    def report(source, message)
      @discrepancies << Discrepancy.new(source, message)
    end
  end
end

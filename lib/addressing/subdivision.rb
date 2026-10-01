# frozen_string_literal: true

module Addressing
  # Represents administrative subdivisions within countries.
  #
  # Subdivisions can be hierarchical with up to three levels:
  # Administrative Area -> Locality -> Dependent Locality
  #
  # @example Get subdivisions for Brazil
  #   states = Addressing::Subdivision.all(['BR'])
  #   states.each do |code, state|
  #     puts "#{code}: #{state.name}"
  #     municipalities = state.children
  #   end
  #
  # @example Get subdivisions for a Brazilian state
  #   municipalities = Addressing::Subdivision.all(['BR', 'CE'])
  class Subdivision
    # The subdivision chain of an address.
    #
    # subdivisions holds the matched predefined subdivisions, ordered from the
    # administrative area downward. unmatched_level is the position, in the
    # values given to Subdivision.chain, of the value that matched no
    # predefined subdivision, or nil when there was none.
    Chain = Data.define(:subdivisions, :unmatched_level)

    class << self
      # Resolves the subdivision chain for the values of the subdivision levels.
      #
      # The walk goes down the levels and stops at the first empty value, at
      # the first value that matches no predefined subdivision, or at a
      # subdivision without children.
      #
      # @param country_code [String] Country code
      # @param values [Array<String, nil>] Values in level order (administrative area, locality, dependent locality)
      # @return [Chain]
      #
      # @example
      #   chain = Addressing::Subdivision.chain("BR", ["CE", "Fortaleza"])
      #   chain.subdivisions.map(&:code) # => ["CE", "Fortaleza"]
      #   chain.unmatched_level          # => nil
      def chain(country_code, values)
        parents = [country_code.upcase]
        subdivisions = []

        # Nothing to match against.
        return Chain.new(subdivisions: subdivisions, unmatched_level: nil) if load_definitions(parents).empty?

        values.each_with_index do |value, level|
          # This level is empty, so there can be no sublevels.
          break if Blank.blank?(value)

          subdivision = get(value, parents)
          return Chain.new(subdivisions: subdivisions, unmatched_level: level) if subdivision.nil?

          subdivisions << subdivision
          # No predefined subdivisions below this level, stop here.
          break unless subdivision.children?

          parents += [value]
        end

        Chain.new(subdivisions: subdivisions, unmatched_level: nil)
      end

      # Gets a Subdivision instance by ID and parent hierarchy.
      #
      # @param id [String] Subdivision ID
      # @param parents [Array<String>] Parent hierarchy (e.g., ['BR'] or ['BR', 'CE'])
      # @return [Subdivision, nil] Subdivision instance or nil if not found
      def get(id, parents)
        definitions = load_definitions(parents)
        create_subdivision_from_definitions(id, definitions)
      end

      # Returns all subdivision instances for the provided parents.
      #
      # @param parents [Array<String>] Parent hierarchy (e.g., ['BR'] or ['BR', 'CE'])
      # @return [Hash<String, Subdivision>] Hash of subdivision ID => Subdivision instance
      def all(parents)
        definitions = load_definitions(parents)
        return {} if definitions.empty?

        definitions["subdivisions"].keys.to_h { |id| [id, create_subdivision_from_definitions(id, definitions)] }
      end

      # Returns a list of subdivisions for the provided parents.
      def list(parents, locale = nil)
        definitions = load_definitions(parents)
        return {} if definitions.empty?

        use_local_name = Locale.match_candidates(locale, definitions["locale"] || "")

        definitions["subdivisions"].transform_values { |definition| use_local_name ? definition["local_name"] : definition["name"] }
      end

      # Gets the key of the subdivision group for the provided parents.
      #
      # The key names the data file of the subdivision group. The data sync
      # names the files with it, so this is the only home of the naming rule.
      #
      # @api private
      # @param parents [Array<String>] Parent hierarchy (e.g., ['BR'] or ['BR', 'CE'])
      # @return [String]
      def group_key(parents)
        raise ArgumentError, "The parents argument must not be empty." if parents.empty?

        # Country codes are matched case-insensitively, subdivision IDs are not.
        country_code = parents[0].upcase
        subdivision_ids = parents.drop(1)

        return country_code if subdivision_ids.empty?

        # The second parent is an ISO code, it can be used as-is.
        return "#{country_code}-#{subdivision_ids[0]}" if subdivision_ids.length == 1 && subdivision_ids[0].length <= 3

        # A dash per key allows the depth to be guessed later.
        # Hash the remaining keys to ensure that the group is ASCII safe.
        country_code + "-" * subdivision_ids.length + Digest::SHA1.hexdigest(subdivision_ids.join("-"))
      end

      protected

      # Loads the subdivision definitions for the provided parents.
      def load_definitions(parents)
        key = group_key(parents)

        (@definitions ||= {})[key] ||= begin
          filename = File.join(File.expand_path("../../../data/subdivision", __FILE__).to_s, "#{key}.json")

          File.exist?(filename) ? process_definitions(parse_definitions(File.read(filename, encoding: "UTF-8"))) : {}
        end
      end

      # Parses a raw definition file.
      #
      # Malformed JSON is treated as if the file didn't exist.
      def parse_definitions(raw_definition)
        definitions = JSON.parse(raw_definition)
        definitions.is_a?(Hash) ? definitions : {}
      rescue JSON::ParserError
        {}
      end

      # Processes the loaded definitions.
      #
      # Adds keys and values that were removed from the JSON files for brevity.
      def process_definitions(definitions)
        # Malformed definitions are treated as if they didn't exist.
        return {} unless definitions["subdivisions"].is_a?(Hash)

        definitions["subdivisions"].each do |id, definition|
          # Upstream writes a definition without keys as an empty JSON array.
          definition = definitions["subdivisions"][id] = {} unless definition.is_a?(Hash)

          # Add common keys from the root level.
          definition["country_code"] = definitions["country_code"]
          definition["id"] = id

          if definitions.key?("locale")
            definition["locale"] = definitions["locale"]
          end

          if !definition.key?("name")
            definition["name"] = id
          end

          # The local_name value is only specified if it doesn't match
          # the name one.
          if definitions.key?("locale") && !definition.key?("local_name")
            definition["local_name"] = definition["name"]
          end

          # The code and local_code values are only specified if they
          # don't match the name and local_name ones.
          if !definition.key?("code")
            definition["code"] = definition["name"]
          end

          if !definition.key?("local_code") && definition.key?("local_name")
            definition["local_code"] = definition["local_name"]
          end
        end

        definitions
      end

      # Creates a subdivision object from the provided definitions.
      def create_subdivision_from_definitions(id, definitions)
        definition = definitions.dig("subdivisions", id)
        # No matching definition found.
        return nil unless definition

        # The 'parents' key is omitted when it contains just the country code.
        parents = definitions["parents"] || [definitions["country_code"]]

        # Load the parent, if known.
        if parents.size > 1
          @parents ||= {}
          parent = @parents[parents] ||= get(parents[-1], parents[0...-1])
        end

        # Prepare children.
        children = definition["has_children"] ? LazySubdivisions.new(parents + [id]) : {}

        new(
          id: id,
          parent: parent,
          country_code: definition["country_code"],
          locale: definition["locale"],
          code: definition["code"],
          local_code: definition["local_code"],
          name: definition["name"],
          local_name: definition["local_name"],
          postal_code_pattern: definition["postal_code_pattern"],
          children: children
        )
      end
    end

    attr_reader :id, :parent, :country_code, :locale, :code, :local_code, :name, :local_name, :postal_code_pattern, :children

    def initialize(definition = {})
      # Validate the presence of required properties.
      [:country_code, :id, :code, :name].each do |required_property|
        if definition[required_property].nil?
          raise ArgumentError, "Missing required property #{required_property}."
        end
      end

      # Add defaults for properties that are allowed to be empty.
      definition = {
        parent: nil,
        locale: nil,
        local_code: nil,
        local_name: nil,
        postal_code_pattern: nil,
        children: {}
      }.merge(definition)

      @id = definition[:id]
      @parent = definition[:parent]
      @country_code = definition[:country_code]
      @locale = definition[:locale]
      @code = definition[:code]
      @local_code = definition[:local_code]
      @name = definition[:name]
      @local_name = definition[:local_name]
      @postal_code_pattern = definition[:postal_code_pattern]
      @children = definition[:children]
    end

    def children?
      @children.any?
    end

    def to_h
      {
        id: id,
        parent: parent,
        country_code: country_code,
        locale: locale,
        code: code,
        local_code: local_code,
        name: name,
        local_name: local_name,
        postal_code_pattern: postal_code_pattern,
        children: children
      }
    end
  end
end

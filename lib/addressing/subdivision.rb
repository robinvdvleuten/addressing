# frozen_string_literal: true

module Addressing
  class Subdivision
    class << self
      # Subdivision definitions.
      @@definitions = {}

      # Parent subdivisions.
      #
      # Used as a cache to speed up instantiating subdivisions with the same
      # parent. Contains only parents instead of all instantiated subdivisions
      # to minimize duplicating the data in $this->definitions, thus reducing
      # memory usage.
      @@parents = {}

      def get(id, parents)
        definitions = load_definitions(parents)
        create_subdivision_from_definitions(id, definitions)
      end

      # Returns all subdivision instances for the provided parents.
      def all(parents)
        definitions = load_definitions(parents)
        return {} if definitions.empty?

        definitions["subdivisions"].each_with_object({}) do |(id, definition), subdivisions|
          subdivisions[id] = create_subdivision_from_definitions(id, definitions)
        end
      end

      # Returns a list of subdivisions for the provided parents.
      def list(parents, locale = nil)
        definitions = load_definitions(parents)
        return {} if definitions.empty?

        use_local_name = Locale.match_candidates(locale, definitions["locale"] || "")

        definitions["subdivisions"].each_with_object({}) do |(id, definition), subdivisions|
          subdivisions[id] = use_local_name ? definition["local_name"] : definition["name"]
        end
      end

      protected

      # Checks whether predefined subdivisions exist for the provided parents.
      def has_data(parents)
        country_code = parents[0]

        depth = AddressFormat.get(country_code).subdivision_depth
        return false if depth == 0

        if parents.size > 1
          # After the first level it is possible for predefined subdivisions
          # to exist at a given level, but not for that specific parent.
          # That's why the parent definition has the most precise answer.
          grandparents = parents.dup
          parent_id = grandparents.pop
          parent_group = build_group(grandparents.dup)

          if @@definitions.dig(parent_group, "subdivisions", parent_id)
            definition = @@definitions[parent_group]["subdivisions"][parent_id]
            return !!definition["has_children"]
          else
            # The parent definition wasn't loaded previously, fallback to guessing based on depth.
            return parents.size <= depth
          end
        end

        # The first level has always data.
        true
      end

      # Loads the subdivision definitions for the provided parents.
      def load_definitions(parents)
        group = build_group(parents.dup)
        if @@definitions.key?(group)
          return @@definitions[group]
        end

        @@definitions[group] = {}

        # If there are predefined subdivisions at this level, try to load them.
        if has_data(parents)
          filename = File.join(File.expand_path("../../../data/subdivision", __FILE__).to_s, "#{group}.json")

          if File.exist?(filename)
            raw_definition = File.read(filename)
            @@definitions[group] = JSON.parse(raw_definition)
            @@definitions[group] = process_definitions(@@definitions[group])
          end
        end

        @@definitions[group]
      end

      # Processes the loaded definitions.
      #
      # Adds keys and values that were removed from the JSON files for brevity.
      def process_definitions(definitions)
        definitions["subdivisions"].each do |id, definition|
          # Add common keys from the root level.
          definition["country_code"] = definitions["country_code"]
          definition["id"] = id

          if definitions.key?("locale")
            definition["locale"] = definitions["locale"]
          end

          if !definition.key?("name")
            definition["name"] = id
          end

          # The code and local_code values are only specified if they
          # don't match the name and local_name ones.
          if !definition.key?("code") && definition.key?("name")
            definition["code"] = definition["name"]
          end

          if !definition.key?("local_code") && definition.key?("local_name")
            definition["local_code"] = definition["local_name"]
          end
        end

        definitions
      end

      # Builds a group from the provided parents.
      #
      # Used for storing a country's subdivisions of a specific level.
      def build_group(parents)
        raise ArgumentError, "The parents argument must not be empty." if parents.empty?

        return parents[0] if parents.length == 1

        # The second parent is an ISO code, it can be used as-is.
        return parents.join("-") if parents.length == 2 && parents[1].length <= 3

        country_code = parents.shift
        group = country_code

        # A dash per key allows the depth to be guessed later.
        group += "-" * parents.length
        # Hash the remaining keys to ensure that the group is ASCII safe.
        group + Digest::SHA1.hexdigest(parents.join("-"))
      end

      # Creates a subdivision object from the provided definitions.
      def create_subdivision_from_definitions(id, definitions)
        if !definitions.dig("subdivisions", id)
          # No matching definition found.
          return nil
        end

        definition = definitions["subdivisions"][id]
        # The 'parents' key is omitted when it contains just the country code.
        definitions["parents"] = [definitions["country_code"]] unless definitions.key?("parents")
        parents = definitions["parents"]

        definition["parent"] = nil

        # Load the parent, if known.
        if parents.size > 1
          grandparents = parents.dup
          parent_id = grandparents.pop
          parent_group = build_group(grandparents.dup)

          if !@@parents.dig(parent_group, parent_id)
            @@parents[parent_group] ||= {}
            @@parents[parent_group][parent_id] = get(parent_id, grandparents)
          end

          definition["parent"] = @@parents[parent_group][parent_id]
        end

        # Prepare children.
        if definition["has_children"]
          children_parents = parents.dup
          children_parents << id

          definition["children"] = LazySubdivisions.new(children_parents)
        end

        new(
          id: id,
          parent: definition["parent"],
          country_code: definition["country_code"],
          locale: definition["locale"],
          code: definition["code"],
          local_code: definition["local_code"],
          name: definition["name"],
          local_name: definition["local_name"],
          postal_code_pattern: definition["postal_code_pattern"],
          children: definition["children"] || {}
        )
      end
    end

    attr_reader :id, :parent, :country_code, :locale, :code, :local_code, :name, :local_name, :postal_code_pattern, :children

    def initialize(definition = {})
      # Validate the presence of required properties.
      [:country_code, :id, :name].each do |required_property|
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

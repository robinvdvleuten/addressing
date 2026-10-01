# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "addressing"

module Addressing
  # Syncs the data files with a checkout of commerceguys/addressing.
  #
  # Upstream keeps part of its data in resource files and part in PHP source.
  # The resource files are copied unchanged, the rest is extracted with PHP.
  # Everything lands under data/, nothing is written into lib/.
  class DataSync
    UPSTREAM_REPOSITORY = "https://github.com/commerceguys/addressing.git"
    UPSTREAM_VERSION = "v2.3.1"

    DEFAULT_DATA_DIR = DataSource::DEFAULT_DIR
    DEFAULT_UPSTREAM_DIR = File.expand_path("../tmp/addressing", __dir__)

    # Runs a PHP script and decodes the JSON it prints.
    PHP = lambda do |script|
      stdout, stderr, status = Open3.capture3("php", "-r", script)
      raise "Unable to run PHP: #{stderr.strip}" unless status.success?

      JSON.parse(stdout)
    rescue Errno::ENOENT
      raise "PHP must be installed to extract the data that upstream keeps in PHP source."
    end

    # @param upstream_dir [String] Checkout of commerceguys/addressing
    # @param data_dir [String] Directory that receives the data files
    # @param version [String] Upstream tag that the checkout holds
    # @param php [#call] Runs a PHP script and returns its decoded JSON output
    def initialize(upstream_dir: DEFAULT_UPSTREAM_DIR, data_dir: DEFAULT_DATA_DIR, version: UPSTREAM_VERSION, php: PHP)
      @upstream_dir = upstream_dir
      @data_dir = data_dir
      @version = version
      @php = php
    end

    # Replaces the upstream checkout with a fresh clone of the version.
    def download
      FileUtils.rm_rf(@upstream_dir)
      system("git", "clone", "--depth", "1", "--branch", @version, UPSTREAM_REPOSITORY, @upstream_dir, exception: true)
    end

    # Replaces the data files with the data of the upstream checkout.
    def sync
      copy_countries
      copy_subdivisions
      write_countries
      write_locale
      write_address_formats

      File.write(File.join(@data_dir, "UPSTREAM_VERSION"), "#{@version}\n")
    end

    # Converts an upstream field name to the name used here.
    #
    # @example
    #   underscore("addressLine1") # => "address_line1"
    def self.underscore(name)
      name.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
    end

    private

    # The locales of the country names are the names of these files.
    def copy_countries
      target = File.join(@data_dir, "country")

      FileUtils.rm_rf(target)
      FileUtils.cp_r(upstream("resources/country"), target)
    end

    # Upstream names a subdivision group file after a Tiger hash, which Ruby
    # has no implementation for. The files are copied byte for byte under the
    # subdivision group key.
    def copy_subdivisions
      target = File.join(@data_dir, "subdivision")

      FileUtils.rm_rf(target)
      FileUtils.mkdir_p(target)

      Dir[upstream("resources/subdivision/*.json")].each do |filename|
        definitions = JSON.parse(File.read(filename, encoding: "UTF-8"))
        group_key = Subdivision.group_key(Subdivision.parents_of(definitions))

        destination = File.join(target, "#{group_key}.json")
        raise "Two upstream files share the subdivision group key #{group_key}" if File.exist?(destination)

        FileUtils.cp(filename, destination)
      end
    end

    def write_countries
      definitions = extract("base definitions from CountryRepository.php", <<~PHP)
        #{require_php("Country/Country.php", "Country/CountryRepositoryInterface.php", "Country/CountryRepository.php")}

        $repository = new CommerceGuys\\Addressing\\Country\\CountryRepository();
        $method = (new ReflectionClass($repository))->getMethod('getBaseDefinitions');

        echo json_encode($method->invoke($repository), JSON_THROW_ON_ERROR);
      PHP

      countries = definitions.to_h do |country_code, (three_letter_code, numeric_code, currency_code)|
        [country_code, {"three_letter_code" => three_letter_code, "numeric_code" => numeric_code, "currency_code" => currency_code}]
      end

      write_json("countries.json", countries)
    end

    def write_locale
      definitions = extract("aliases and parents from Locale.php", <<~PHP)
        #{require_php("Locale.php")}

        $reflection = new ReflectionClass('CommerceGuys\\Addressing\\Locale');

        echo json_encode([
            'aliases' => $reflection->getProperty('aliases')->getValue(),
            'parents' => $reflection->getProperty('parents')->getValue(),
        ], JSON_THROW_ON_ERROR);
      PHP

      unless definitions["aliases"].is_a?(Hash) && definitions["parents"].is_a?(Hash)
        raise "Unable to extract aliases and parents from Locale.php"
      end

      write_json("locale.json", definitions)
    end

    def write_address_formats
      definitions = extract("definitions from AddressFormatRepository.php", <<~PHP)
        #{require_php("AddressFormat/AddressFormat.php", "AddressFormat/AddressFormatRepositoryInterface.php", "AddressFormat/AddressFormatRepository.php")}

        $repository = new CommerceGuys\\Addressing\\AddressFormat\\AddressFormatRepository();
        $method = (new ReflectionClass($repository))->getMethod('getDefinitions');

        echo json_encode($method->invoke($repository), JSON_THROW_ON_ERROR);
      PHP

      address_formats = definitions.to_h do |country_code, definition|
        [country_code, {"country_code" => country_code}.merge(normalize_address_format(definition))]
      end

      write_json("address_formats.json", address_formats)
    end

    # Upstream names fields in camelCase, the address formats here use snake_case.
    def normalize_address_format(definition)
      definition = definition.dup

      ["format", "local_format"].each do |key|
        definition[key] = definition[key].gsub(/%[[:alnum:]]+/) { |placeholder| self.class.underscore(placeholder) } if definition.key?(key)
      end

      ["required_fields", "uppercase_fields"].each do |key|
        definition[key] = definition[key].map { |field| self.class.underscore(field) } if definition.key?(key)
      end

      if definition.key?("subdivision_data_fields")
        definition["subdivision_fields"] = definition.delete("subdivision_data_fields").map { |field| self.class.underscore(field) }
      end

      definition
    end

    # Runs the PHP script and checks that it found something.
    def extract(description, script)
      result = @php.call("error_reporting(E_ALL & ~E_DEPRECATED);\n#{script}")
      raise "Unable to extract #{description}" unless result.is_a?(Hash) && result.any?

      result
    end

    def require_php(*files)
      files.map { |file| "require '#{upstream("src/#{file}")}';" }.join("\n")
    end

    def write_json(name, content)
      File.write(File.join(@data_dir, name), "#{JSON.pretty_generate(content)}\n")
    end

    def upstream(path)
      File.join(@upstream_dir, path)
    end
  end
end

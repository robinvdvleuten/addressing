REPO_DIR = File.expand_path("../../tmp/addressing", __FILE__)

namespace :addressing do
  task :generate_address_data do
    require "json"

    # Require ActiveRecord to have access to the underscore method.
    require "active_record"

    # Make sure PHP is installed.
    php_version = `php --version`
    raise "PHP must be installed." if php_version.empty? || php_version.index("PHP").nil?

    address_format_repo = File.read("tmp/addressing/src/AddressFormat/AddressFormatRepository.php")

    puts "Extracting definitions from AddressFormatRepository.php\n"

    # Extract definitions from the getDefinitions() method.
    definitions_match = address_format_repo.match(/getDefinitions\(\): array\s*\{.+?(\$.*\];)/m)
    raise "Unable to extract definitions from AddressFormatRepository.php" if definitions_match.nil?

    # Moving the extracted definitions to PHP file."
    File.write("tmp/definitions.php", "<?php\n#{definitions_match[1]}\necho json_encode($definitions);")

    # Retrieve definitions from PHP file as JSON.
    system "php tmp/definitions.php > tmp/definitions.json"

    definitions = JSON.parse(File.read("tmp/definitions.json"))

    lines = definitions.map do |country_code, definition|
      normalize_definition(definition)
      JSON.generate({"country_code" => country_code}.merge(definition))
    end

    puts "Writing definitions to data\n"
    File.write("data/address_formats.json", lines.join("\n"))
  end
end

def normalize_definition(definition)
  definition["format"] = definition["format"].gsub(/%[[:alnum:]]+/) { |m| m.underscore } if definition.key?("format")
  definition["local_format"] = definition["local_format"].gsub(/%[[:alnum:]]+/) { |m| m.underscore } if definition.key?("local_format")
  definition["required_fields"] = definition["required_fields"].map(&:underscore) if definition.key?("required_fields")
  definition["uppercase_fields"] = definition["uppercase_fields"].map(&:underscore) if definition.key?("uppercase_fields")
end

LOCALE_DIR = File.expand_path("../../tmp/cldr/cldr-json/cldr-localenames-modern/main", __FILE__)

namespace :addressing do
  task :generate do
    require "digest"
    require "json"

    # Require ActiveRecord to have access to the underscore method.
    require "active_record"

    # Make sure PHP is installed as well.
    php_version = `php --version`
    raise "PHP must be installed." if php_version.empty? || php_version.index("PHP").nil?

    puts "Copying country data."
    FileUtils.remove_dir("data/country", true)
    FileUtils.cp_r("tmp/addressing/resources/country", "data", remove_destination: true)

    puts "Copying subdivision data."
    FileUtils.remove_dir("data/subdivision", true)
    FileUtils.cp_r("tmp/addressing/resources/subdivision", "data", remove_destination: true)

    puts "Normalizing data in subdivision files."

    # Replace [] with {} in subdivision files, as our codes expect a hash
    # instead of an associate array when decoding from JSON.
    system "find ./data/subdivision -type f -exec sed -i '' -e 's/\\[\\]/\\{\\}/g' {} \\;"

    # Child subdivisions have their parents as Tiger encoded hash within the filename for easier lookups.
    # As Ruby has no support for this hashing algorithm, we'll need to convert the hashes to SHA1.
    normalize_subdivision_group_hash

    puts "Extracting definitions from AddressFormatRepository.php\n"
    extract_address_definitions

    puts "Done."
  end
end

def normalize_subdivision_group_hash
  Dir.glob("data/subdivision/*-*.json").each do |file|
    subdivision = JSON.parse(File.read(file))
    parents = subdivision["parents"]

    filename = parents.shift
    next unless parents.any?

    filename += "-" * parents.length
    filename += Digest::SHA1.hexdigest(parents.join("-"))
    filename += ".json"

    File.rename(file, "data/subdivision/#{filename}")
  end
end

def extract_address_definitions
  address_format_repo = File.read("tmp/addressing/src/AddressFormat/AddressFormatRepository.php")

  # Extract definitions from the getDefinitions() method.
  definitions_match = address_format_repo.match(/getDefinitions\(\): array\s*\{.+?(\[.*\]);/m)
  raise "Unable to extract definitions from AddressFormatRepository.php" if definitions_match.nil?

  # Moving the extracted definitions to PHP file."
  File.write("tmp/definitions.php", "<?php\n$definitions = #{definitions_match[1]};\necho json_encode($definitions);")

  # Retrieve definitions from PHP file as JSON.
  system "php tmp/definitions.php > tmp/definitions.json"

  definitions = JSON.parse(File.read("tmp/definitions.json"))

  lines = definitions.map do |country_code, definition|
    normalize_definition(definition)
    JSON.generate({"country_code" => country_code}.merge(definition))
  end

  File.write("data/address_formats.json", lines.join("\n"))
end

def normalize_definition(definition)
  definition["format"] = definition["format"].gsub(/%[[:alnum:]]+/) { |m| m.underscore } if definition.key?("format")
  definition["local_format"] = definition["local_format"].gsub(/%[[:alnum:]]+/) { |m| m.underscore } if definition.key?("local_format")
  definition["required_fields"] = definition["required_fields"].map(&:underscore) if definition.key?("required_fields")
  definition["uppercase_fields"] = definition["uppercase_fields"].map(&:underscore) if definition.key?("uppercase_fields")
end

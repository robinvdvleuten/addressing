LOCALE_DIR = File.expand_path("../../tmp/cldr/cldr-json/cldr-localenames-modern/main", __FILE__)

namespace :addressing do
  task generate: :download do
    require "digest"
    require "json"
    require "open3"

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

    puts "Extracting available locales from CountryRepository.php\n"
    extract_available_locales

    puts "Extracting base definitions from CountryRepository.php\n"
    extract_base_definitions

    puts "Extracting locale definitions from Locale.php\n"
    extract_locale_definitions

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
    next unless parents.any? && !(parents.length == 1 && parents[0].length <= 3)

    filename += "-" * parents.length
    filename += Digest::SHA1.hexdigest(parents.join("-"))
    filename += ".json"

    File.rename(file, "data/subdivision/#{filename}")
  end
end

def extract_available_locales
  locales = extract_php_json("country_locales", <<~PHP)
    require 'tmp/addressing/src/Country/Country.php';
    require 'tmp/addressing/src/Country/CountryRepositoryInterface.php';
    require 'tmp/addressing/src/Country/CountryRepository.php';

    $repository = new CommerceGuys\\Addressing\\Country\\CountryRepository();
    $reflection = new ReflectionClass($repository);
    $availableLocales = $reflection->getProperty('availableLocales')->getValue($repository);

    echo json_encode($availableLocales, JSON_THROW_ON_ERROR);
  PHP

  raise "Unable to extract available locales from CountryRepository.php" unless locales.is_a?(Array) && locales.any?

  country_rb = File.read("lib/addressing/country.rb")
  country_rb = replace_or_raise(
    country_rb,
    /AVAILABLE_LOCALES = \[[^\]]+\]/m,
    "AVAILABLE_LOCALES = #{format_ruby_array_like_php(
      locales,
      "tmp/addressing/src/Country/CountryRepository.php",
      "$availableLocales",
      indent: 8
    )}",
    "AVAILABLE_LOCALES"
  )

  File.write("lib/addressing/country.rb", country_rb)
end

def extract_base_definitions
  definitions = extract_php_json("country_base_definitions", <<~PHP)
    require 'tmp/addressing/src/Country/Country.php';
    require 'tmp/addressing/src/Country/CountryRepositoryInterface.php';
    require 'tmp/addressing/src/Country/CountryRepository.php';

    $repository = new CommerceGuys\\Addressing\\Country\\CountryRepository();
    $reflection = new ReflectionClass($repository);
    $method = $reflection->getMethod('getBaseDefinitions');
    $baseDefinitions = $method->invoke($repository);

    echo json_encode($baseDefinitions, JSON_THROW_ON_ERROR);
  PHP

  raise "Unable to extract base definitions from CountryRepository.php" unless definitions.is_a?(Hash) && definitions.any?

  country_rb = File.read("lib/addressing/country.rb")
  country_rb = replace_or_raise(
    country_rb,
    /^        @base_definitions \|\|= \{\n.*?^        \}/m,
    "        @base_definitions ||= #{format_ruby_hash(definitions, indent: 10)}",
    "@base_definitions"
  )

  File.write("lib/addressing/country.rb", country_rb)
end

def extract_address_definitions
  definitions = extract_php_json("address_definitions", <<~PHP)
    require 'tmp/addressing/src/AddressFormat/AddressFormat.php';
    require 'tmp/addressing/src/AddressFormat/AddressFormatRepositoryInterface.php';
    require 'tmp/addressing/src/AddressFormat/AddressFormatRepository.php';

    $repository = new CommerceGuys\\Addressing\\AddressFormat\\AddressFormatRepository();
    $reflection = new ReflectionClass($repository);
    $method = $reflection->getMethod('getDefinitions');
    $definitions = $method->invoke($repository);

    echo json_encode($definitions, JSON_THROW_ON_ERROR);
  PHP

  raise "Unable to extract definitions from AddressFormatRepository.php" unless definitions.is_a?(Hash) && definitions.any?

  lines = definitions.map do |country_code, definition|
    normalize_definition(definition)
    JSON.generate({"country_code" => country_code}.merge(definition))
  end

  File.write("data/address_formats.json", lines.join("\n"))
end

def extract_locale_definitions
  definitions = extract_php_json("locale_definitions", <<~PHP)
    require 'tmp/addressing/src/Locale.php';

    $reflection = new ReflectionClass('CommerceGuys\\\\Addressing\\\\Locale');
    $aliases = $reflection->getProperty('aliases')->getValue();
    $parents = $reflection->getProperty('parents')->getValue();

    echo json_encode([
        'aliases' => $aliases,
        'parents' => $parents,
    ], JSON_THROW_ON_ERROR);
  PHP

  aliases = definitions["aliases"]
  parents = definitions["parents"]

  unless aliases.is_a?(Hash) && aliases.any? && parents.is_a?(Hash) && parents.any?
    raise "Unable to extract locale definitions from Locale.php"
  end

  locale_rb = File.read("lib/addressing/locale.rb")
  locale_rb = replace_or_raise(
    locale_rb,
    /ALIASES = \{.*?\n    \}\.freeze/m,
    "ALIASES = #{format_ruby_hash(aliases, indent: 6)}.freeze",
    "ALIASES"
  )
  locale_rb = replace_or_raise(
    locale_rb,
    /PARENTS = \{.*?\n    \}\.freeze/m,
    "PARENTS = #{format_ruby_hash(parents, indent: 6)}.freeze",
    "PARENTS"
  )

  File.write("lib/addressing/locale.rb", locale_rb)
end

def normalize_definition(definition)
  definition["format"] = definition["format"].gsub(/%[[:alnum:]]+/) { |m| m.underscore } if definition.key?("format")
  definition["local_format"] = definition["local_format"].gsub(/%[[:alnum:]]+/) { |m| m.underscore } if definition.key?("local_format")
  definition["required_fields"] = definition["required_fields"].map(&:underscore) if definition.key?("required_fields")
  definition["uppercase_fields"] = definition["uppercase_fields"].map(&:underscore) if definition.key?("uppercase_fields")
end

def extract_php_json(name, php_code)
  FileUtils.mkdir_p("tmp")

  script_path = "tmp/#{name}.php"
  File.write(script_path, "<?php\nerror_reporting(E_ALL & ~E_DEPRECATED);\n#{php_code}")

  stdout, stderr, status = Open3.capture3("php", script_path)
  unless status.success?
    raise "Unable to execute #{script_path}: #{stderr.strip}"
  end

  JSON.parse(stdout)
rescue JSON::ParserError => e
  raise "Unable to parse JSON from #{script_path}: #{e.message}"
end

def replace_or_raise(source, pattern, replacement, name)
  raise "Unable to replace #{name}" unless source.match?(pattern)

  source.sub(pattern, replacement)
end

def format_ruby_array(values, indent:, max_length: 100)
  lines = []
  current_line = []

  values.each do |value|
    literal = ruby_literal(value)
    next_line = [*current_line, literal]

    if current_line.any? && "#{" " * indent}#{next_line.join(", ")}".length > max_length
      lines << "#{" " * indent}#{current_line.join(", ")}"
      current_line = [literal]
    else
      current_line = next_line
    end
  end

  lines << "#{" " * indent}#{current_line.join(", ")}" if current_line.any?

  "[\n#{lines.join(",\n")}\n#{" " * (indent - 2)}]"
end

def format_ruby_array_like_php(values, php_file, php_variable, indent:)
  group_sizes = php_array_group_sizes(php_file, php_variable)
  return format_ruby_array(values, indent: indent) unless group_sizes.sum == values.length

  lines = []
  offset = 0

  group_sizes.each do |group_size|
    group = values[offset, group_size]
    lines << "#{" " * indent}#{group.map { |value| ruby_literal(value) }.join(", ")}"
    offset += group_size
  end

  "[\n#{lines.join(",\n")}\n#{" " * (indent - 2)}]"
end

def php_array_group_sizes(php_file, php_variable)
  source = File.read(php_file)
  match = source.match(/#{Regexp.escape(php_variable)} = \[\n(?<body>.*?)^\s+\];/m)
  raise "Unable to extract #{php_variable} grouping from #{php_file}" if match.nil?

  match[:body].lines.map do |line|
    line.scan(/'[^']*'/).count
  end.reject(&:zero?)
end

def format_ruby_hash(values, indent:)
  lines = values.map do |key, value|
    "#{" " * indent}#{ruby_literal(key)} => #{ruby_literal(value)}"
  end

  "{\n#{lines.join(",\n")}\n#{" " * (indent - 2)}}"
end

def ruby_literal(value)
  case value
  when String
    value.inspect
  when NilClass
    "nil"
  when Array
    "[#{value.map { |item| ruby_literal(item) }.join(", ")}]"
  else
    raise "Unsupported generated value: #{value.inspect}"
  end
end

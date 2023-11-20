namespace :addressing do
  task :generate_address_data do
    require "addressing"
    require "json"
    require "open-uri"

    require_relative "../data/library_customizations"

    service_url = "https://chromium-i18n.appspot.com/ssl-address"

    # Make sure we're starting from a clean slate.
    raise "The tmp/subdivision directory already exists." if Dir.exist?("tmp/subdivision")

    # Prepare the filesystem.
    FileUtils.mkdir_p "tmp/subdivision"

    countries = Addressing::Country.list.sort.to_h
    index = URI.open(service_url).read

    found_countries = countries.each_with_object(["ZZ"]) do |(country_code, country_name), found_countries|
      link = "<a href='/ssl-address/data/#{country_code}'>"
      # This is still faster than running a File.exist? for each country code.
      if index.index(link)
        found_countries << country_code
      end
    end

    puts "Converting the raw definitions into the expected format."

    address_formats, grouped_subdivisions = found_countries.inject([{}, {}]) do |(address_formats, grouped_subdivisions), country_code|
      definition = JSON.parse(File.read("tmp/google/#{country_code}.json"))

      extra_keys = definition.keys - %w[id key name]
      if extra_keys.empty?
        # This is an empty definition, skip it.
        next [address_formats, grouped_subdivisions]
      end

      if country_code == "MO"
        # Fix for Macao, which has latin and non-latin formats, but no lang.
        definition["lang"] = "zh"
      end

      address_format = create_address_format_definition(country_code, definition)

      # Get the French subdivision names for Canada.
      # This mechanism can only work for countries with a single
      # alternative language and ISO-based subdivision codes
      # (URL example: data/CA/AB and data/CA/AB--fr).
      languages = []
      if country_code == "CA" && definition["languages"]
        languages = definition["languages"].split("~")
        languages.shift
      end

      subdivision_paths = []
      if definition.key?("sub_keys")
        subdivision_keys = definition["sub_keys"].split("~")
        subdivision_keys.each do |subdivision_key|
          subdivision_paths << "#{country_code}_#{subdivision_key}"
        end
      end

      grouped_subdivisions = grouped_subdivisions.merge(generate_subdivisions(country_code, [country_code], subdivision_paths, languages))
      address_formats[country_code] = address_format

      [address_formats, grouped_subdivisions]
    end

    puts "Writing the final definitions to disk."

    # Subdivisions are stored in JSON.
    grouped_subdivisions.each_with_index do |(parent_id, grouped_subdivision)|
      File.write("tmp/subdivision/#{parent_id}.json", JSON.pretty_generate(grouped_subdivision))
    end

    # Replace subdivision/ES.json with the old resources/subdivision/ES.json, to
    # get around a dataset regression (https://github.com/googlei18n/libaddressinput/issues/160).
    FileUtils.cp("data/subdivision/ES.json", "tmp/subdivision/ES.json")

    # Generate the subdivision depths for each country.
    generate_subdivision_depths(found_countries).each do |country_code, depth|
      address_formats[country_code] ||= {}
      address_formats[country_code]["subdivision_depth"] = depth
    end

    # Address formats are stored in JSON, then manually dumped to Ruby.
    File.open("data/address_formats.json", "w") do |f|
      address_formats.each do |(country_code, address_format)|
        f << "#{JSON.generate({"country_code" => country_code}.merge(address_format), space: " ")}\n"
      end
    end

    FileUtils.cp_r("tmp/subdivision/", "data", remove_destination: true)

    puts "Done."
  end
end

# Recursively generates subdivision definitions.
def generate_subdivisions(country_code, parents, subdivision_paths, languages)
  group = Addressing::Subdivision.send(:build_group, parents.dup)

  subdivisions = {
    group => {
      "country_code" => country_code
    }
  }

  if parents.size > 1
    # A single parent is the same as the country code, hence unnecessary.
    subdivisions[group]["parents"] = parents
  end

  subdivision_paths.each do |subdivision_path|
    definition = JSON.parse(File.read("tmp/google/#{subdivision_path}.json"))

    # The lname is usable as a latin code when the key is non-latin.
    code = definition.key?("lname") ? definition["lname"] : definition["key"]

    if !subdivisions[group].key?("locale") && definition.key?("lang") && definition.key?("lname")
      # Only add the locale if there's a local name.
      subdivisions[group]["locale"] = process_locale(definition["lang"])
    end

    # (Ab)use the local_name field to hold latin translations. This allows
    # us to support only a single translation, but since our only example
    # here is Canada (with French), it will do.
    translation_language = languages.first
    if translation_language
      translation = JSON.parse(File.read("tmp/google/#{subdivision_path}--#{translation_language}.json"))
      subdivisions[group]["locale"] = Addressing::Locale.canonicalize(translation_language)
      definition["lname"] = definition["name"]
      definition["name"] = translation["name"]
    end

    # Remove the locale key if it wasn't filled.
    subdivisions[group].delete("locale") if !subdivisions[group].key?("locale")

    # Generate the subdivision.
    subdivisions[group]["subdivisions"] ||= {}
    subdivisions[group]["subdivisions"][code] = create_subdivision_definition(country_code, code, definition)

    if definition.key?("sub_keys")
      subdivisions[group]["subdivisions"][code]["has_children"] = true

      subdivision_children_paths = []
      subdivision_children_keys = definition["sub_keys"].split("~")
      subdivision_children_keys.each do |subdivision_children_key|
        subdivision_children_paths << subdivision_path + "_" + subdivision_children_key
      end

      child_parents = parents + [code]
      subdivisions.merge!(generate_subdivisions(country_code, child_parents, subdivision_children_paths, languages))
    end
  end

  # Apply any found customizations.
  customizations = subdivision_customizations(group)
  subdivisions[group] = apply_subdivision_customizations(subdivisions[group], customizations)

  subdivisions[group].key?("subdivisions") ? subdivisions : {}
end

# Generates the subdivision depths for each country.
def generate_subdivision_depths(countries)
  countries.each_with_object({}) do |country_code, depths|
    patterns = [
      "tmp/subdivision/#{country_code}.json",
      "tmp/subdivision/#{country_code}-*.json",
      "tmp/subdivision/#{country_code}--*.json"
    ]

    patterns.each do |pattern|
      break if Dir.glob(pattern).empty?

      depths[country_code] = (depths[country_code] || 0) + 1
    end
  end
end

# Creates an address format definition from Google's raw definition.
def create_address_format_definition(country_code, raw_definition)
  # Avoid notices.
  raw_definition = {
    "lang" => nil,
    "fmt" => nil,
    "require" => nil,
    "upper" => nil,
    "state_name_type" => nil,
    "locality_name_type" => nil,
    "sublocality_name_type" => nil,
    "zip_name_type" => nil
  }.merge(raw_definition)

  # ZZ holds the defaults for all address formats, and these are missing.
  if country_code == "ZZ"
    raw_definition["state_name_type"] = Addressing::AdministrativeAreaType.default
    raw_definition["sublocality_name_type"] = Addressing::DependentLocalityType.default
    raw_definition["zip_name_type"] = Addressing::PostalCodeType.default
  end

  address_format = {
    "locale" => process_locale(raw_definition["lang"]),
    "format" => nil,
    "local_format" => nil,
    "required_fields" => convert_fields(raw_definition["require"], "required"),
    "uppercase_fields" => convert_fields(raw_definition["upper"], "uppercase")
  }

  if raw_definition.key?("lfmt") && raw_definition["lfmt"] != raw_definition["fmt"]
    address_format["format"] = convert_format(country_code, raw_definition["lfmt"])
    address_format["local_format"] = convert_format(country_code, raw_definition["fmt"])
  else
    address_format["format"] = convert_format(country_code, raw_definition["fmt"])
    # We don't need the locale if there's no local format.
    address_format.delete("locale")
  end

  address_format["administrative_area_type"] = raw_definition["state_name_type"]
  address_format["locality_type"] = raw_definition["locality_name_type"]
  address_format["dependent_locality_type"] = raw_definition["sublocality_name_type"]
  address_format["postal_code_type"] = raw_definition["zip_name_type"]
  address_format["postal_code_pattern"] = raw_definition["zip"] if raw_definition.key?("zip")

  if raw_definition.key?("postprefix")
    # Workaround for https://github.com/googlei18n/libaddressinput/issues/72.
    raw_definition["postprefix"] = "PR " if raw_definition["postprefix"] == "PR"

    address_format["postal_code_prefix"] = raw_definition["postprefix"]

    # Remove the prefix from the format strings.
    # Workaround for https://github.com/googlei18n/libaddressinput/issues/71.
    address_format["format"] = address_format["format"].gsub(address_format["postal_code_prefix"], "")
    address_format["local_format"] = address_format["local_format"].gsub(address_format["postal_code_prefix"], "") unless address_format["local_format"].nil?
  end

  # Add the subdivision_depth to the end of the ZZ definition.
  address_format["subdivision_depth"] = 0 if country_code == "ZZ"

  # Remove multiple spaces in the formats.
  address_format["format"] = address_format["format"].gsub!(/[[:blank:]]+/, " ") if address_format.key?("format") && !address_format["format"].nil?
  address_format["local_format"] = address_format["local_format"].gsub!(/[[:blank:]]+/, " ") if address_format.key?("local_format") && !address_format["local_format"].nil?

  # Apply any customizations.
  customizations = address_format_customizations(country_code)
  customizations.each_with_object(address_format) do |(key, values), address_format|
    address_format[key] = values
  end

  # Remove nil keys.
  address_format = address_format.reject { |_, value| value.nil? }

  # Remove empty local formats.
  address_format.delete("local_format") if address_format.key?("local_format") && (address_format["local_format"].nil? || address_format["local_format"].empty?)

  address_format
end

# Creates a subdivision definition from Google's raw definition.
def create_subdivision_definition(country_code, code, raw_definition)
  subdivision = {}

  if raw_definition.key?("lname")
    subdivision["local_code"] = raw_definition["key"]

    if raw_definition.key?("name") && raw_definition["key"] != raw_definition["name"]
      subdivision["local_name"] = raw_definition["name"]
    end

    if code != raw_definition["lname"]
      subdivision["name"] = raw_definition["lname"]
    end
  elsif raw_definition.key?("name") && raw_definition["key"] != raw_definition["name"]
    subdivision["name"] = raw_definition["name"]
  end

  if raw_definition.key?("isoid")
    subdivision["iso_code"] = country_code + "-" + raw_definition["isoid"]
  end

  if raw_definition.key?("xzip")
    subdivision["postal_code_pattern"] = raw_definition["xzip"]
  end

  subdivision
end

def apply_subdivision_customizations(subdivisions, customizations)
  return subdivisions if customizations.empty?

  subdivisions["subdivisions"] ||= {}

  customizations = {
    "_remove" => [],
    "_replace" => [],
    "_add" => [],
    "_add_after" => []
  }.merge(customizations)

  customizations["_remove"].each do |remove_id|
    subdivisions["subdivisions"].delete(remove_id)
  end

  customizations["_replace"].each do |replace_id|
    subdivisions["subdivisions"][replace_id] = customizations[replace_id]
  end

  customizations["_add"].each do |add_id|
    subdivisions["subdivisions"][add_id] = customizations[add_id]
  end

  customizations["_add_after"].each do |add_id, next_id|
    position = subdivisions["subdivisions"].keys.index(next_id)

    start = subdivisions["subdivisions"].slice(0, position)
    end_ = subdivisions["subdivisions"].slice(position)
    subdivisions["subdivisions"] = start.merge({add_id => customizations[add_id]}).merge(end_)
  end

  subdivisions
end

# Processes the locale string.
def process_locale(locale)
  if locale == "zh"
    locale = "zh-hans"
  end

  Addressing::Locale.canonicalize(locale)
end

# Converts Google's field symbols to the expected values.
def convert_fields(fields, type)
  return nil if fields.nil?
  return [] if fields.empty?

  # Expand the name token into separate tokens.
  fields = if type == "required"
    # The additional name is never required.
    fields.gsub("N", "79")
  else
    fields.gsub("N", "789")
  end

  # Expand the address token into separate tokens for address lines 1 and 2.
  # For required fields it's enough to require the first line.
  fields = if type == "required"
    fields.tr("A", "1")
  else
    fields.gsub("A", "12")
  end

  mapping = {
    "S" => Addressing::AddressField::ADMINISTRATIVE_AREA,
    "C" => Addressing::AddressField::LOCALITY,
    "D" => Addressing::AddressField::DEPENDENT_LOCALITY,
    "Z" => Addressing::AddressField::POSTAL_CODE,
    "X" => Addressing::AddressField::SORTING_CODE,
    "1" => Addressing::AddressField::ADDRESS_LINE1,
    "2" => Addressing::AddressField::ADDRESS_LINE2,
    "O" => Addressing::AddressField::ORGANIZATION,
    "7" => Addressing::AddressField::FAMILY_NAME,
    "8" => Addressing::AddressField::ADDITIONAL_NAME,
    "9" => Addressing::AddressField::GIVEN_NAME
  }

  fields.chars.map { |field| mapping.key?(field) ? mapping[field] : field }
end

# Converts the provided format string into one recognized by the library.
def convert_format(country_code, format)
  return nil if format.nil?

  # Expand the recipient token into separate familyName/givenName tokens.
  # The additionalName field is not used by default.
  # Hardcode the list of countries that write the family name before the
  # given name, since the API doesn't give us that info.
  reverse_countries = [
    "KH", "CN", "HU", "JP", "KO", "MG", "TW", "VN"
  ]

  format = if reverse_countries.include?(country_code)
    format.gsub("%N", "%N3 %N1")
  else
    format.gsub("%N", "%N1 %N3")
  end

  # Expand the address token into separate tokens for address lines 1 and 2.
  format = format.gsub("%A", "%1%n%2")

  replacements = {
    "%S" => "%" + Addressing::AddressField::ADMINISTRATIVE_AREA,
    "%C" => "%" + Addressing::AddressField::LOCALITY,
    "%D" => "%" + Addressing::AddressField::DEPENDENT_LOCALITY,
    "%Z" => "%" + Addressing::AddressField::POSTAL_CODE,
    "%X" => "%" + Addressing::AddressField::SORTING_CODE,
    "%1" => "%" + Addressing::AddressField::ADDRESS_LINE1,
    "%2" => "%" + Addressing::AddressField::ADDRESS_LINE2,
    "%O" => "%" + Addressing::AddressField::ORGANIZATION,
    "%N3" => "%" + Addressing::AddressField::FAMILY_NAME,
    "%N2" => "%" + Addressing::AddressField::ADDITIONAL_NAME,
    "%N1" => "%" + Addressing::AddressField::GIVEN_NAME,
    "%n" => "\n",
    # Remove hardcoded strings which duplicate the country name.
    "%nÅLAND" => "",
    "JERSEY%n" => "",
    "GUERNSEY%n" => "",
    "GIBRALTAR%n" => "",
    "SINGAPORE " => ""
  }

  format.gsub(/%[a-zA-Z1-9_]+/) { |m| replacements[m] }
end

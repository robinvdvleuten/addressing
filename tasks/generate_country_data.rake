LOCALE_DIR = File.expand_path("../../tmp/cldr/cldr-json/cldr-localenames-modern/main", __FILE__)

namespace :addressing do
  task :generate_country_data do
    require "addressing"
    require "date"
    require "ffi-icu"
    require "json"

    # Make sure we're starting from a clean slate.
    raise "The tmp/country directory already exists." if Dir.exist?("tmp/country")

    # Prepare the filesystem.
    FileUtils.mkdir_p "tmp/country"

    english_data = File.join(LOCALE_DIR, "en/territories.json")
    raise "The #{english_data} file cannot be found." unless File.exist?(english_data)

    english_data = JSON.parse(File.read(english_data))
    english_data = english_data["main"]["en"]["localeDisplayNames"]["territories"]

    code_mappings = File.expand_path("../../tmp/cldr/cldr-json/cldr-core/supplemental/codeMappings.json", __FILE__)
    raise "The #{code_mappings} file cannot be found." unless File.exist?(code_mappings)

    code_mappings = JSON.parse(File.read(code_mappings))
    code_mappings = code_mappings["supplemental"]["codeMappings"]

    currency_data = File.expand_path("../../tmp/cldr/cldr-json/cldr-core/supplemental/currencyData.json", __FILE__)
    raise "The #{currency_data} file cannot be found." unless File.exist?(currency_data)

    currency_data = JSON.parse(File.read(currency_data))
    currency_data = currency_data["supplemental"]["currencyData"]

    base_data = generate_base_data(english_data, code_mappings, currency_data)
    localizations = generate_localizations(base_data, english_data)
    localizations = filter_duplicate_localizations(localizations)

    # Write out the localizations.
    localizations.each do |locale, localized_countries|
      collator = ICU::Collation::Collator.new(locale)
      sorted_countries = localized_countries.sort { |a, b| collator.compare(a[1], b[1]) }.to_h

      File.write("tmp/country/#{locale}.json", JSON.pretty_generate(sorted_countries))
    end

    FileUtils.cp_r("tmp/country/", "data", remove_destination: true)

    # p localizations.keys.sort

    # export_base_data = base_data.each do |country_code, country_data|
    #   three_letter_code = country_data.key?("three_letter_code") ? "\"#{country_data["three_letter_code"]}\"" : "nil"
    #   numeric_code = country_data.key?("numeric_code") ? "\"#{country_data["numeric_code"]}\"" : "nil"
    #   currency_code = country_data.key?("currency_code") ? "\"#{country_data["currency_code"]}\"" : "nil"

    #   puts "\"#{country_code}\" => [#{three_letter_code}, #{numeric_code}, #{currency_code}],"
    # end

    puts "Done."
  end
end

# Generates the base data.
def generate_base_data(english_data, code_mappings, currency_data)
  ignored_countries = [
    "AN", # Netherlands Antilles, no longer exists.
    "EU", "QO", # European Union, Outlying Oceania. Not countries.
    "XA", "XB",
    "ZZ" # Unknown region
  ]

  base_data = english_data.each_with_object({}) do |(country_code, country_name), base_data|
    if begin
      Float(country_code)
    rescue
      false
    end || ignored_countries.include?(country_code)
      # Ignore continents, regions, uninhabited islands.
      next base_data
    end

    if country_code.include?("-alt-")
      # Ignore alternative names.
      next base_data
    end

    # Countries are not guaranteed to have an alpha3 and/or numeric code.
    if code_mappings[country_code]&.key?("_alpha3")
      base_data[country_code] ||= {}
      base_data[country_code]["three_letter_code"] = code_mappings[country_code]["_alpha3"]
    end

    if code_mappings[country_code]&.key?("_numeric")
      base_data[country_code] ||= {}
      base_data[country_code]["numeric_code"] = code_mappings[country_code]["_numeric"]
    end

    # Determine the current currency for this country.
    if currency_data["region"].key?(country_code)
      currencies = prepare_currencies(currency_data["region"][country_code])

      unless currencies.empty?
        currency_codes = currencies.keys
        current_currency = currency_codes.last

        base_data[country_code] ||= {}
        base_data[country_code]["currency_code"] = current_currency
      end
    end
  end

  base_data.sort.to_h
end

# Generates the localizations.
def generate_localizations(base_data, english_data)
  discover_locales.inject({}) do |localizations, locale|
    data = JSON.parse(File.read(File.join(LOCALE_DIR, locale, "territories.json")))
    data = data["main"][locale]["localeDisplayNames"]["territories"]

    data.each_with_object(localizations) do |(country_code, country_name), localizations|
      if base_data.key?(country_code)
        # This country name is untranslated, use the english version.
        if country_code == country_name.tr("_", "-")
          country_name = english_data[country_code]
        end

        localizations[locale] ||= {}
        localizations[locale][country_code] = country_name
      end
    end
  end
end

# Filters out duplicate localizations (same as their parent locale).
#
# For example, "fr-FR" will be removed if "fr" has the same data.
def filter_duplicate_localizations(localizations)
  duplicates = localizations.each_with_object([]) do |(locale, localized_countries), duplicates|
    if (parent_locale = Addressing::Locale.parent(locale))
      parent_countries = localizations[parent_locale] || {}
      diff = localized_countries.values - parent_countries.values

      if diff.empty?
        # The duplicates are not removed right away because they might
        # still be needed for other duplicate checks (for example,
        # when there are locales like bs-Latn-BA, bs-Latn, bs).
        duplicates << locale
      end
    end
  end

  duplicates.each_with_object(localizations) do |locale, localizations|
    localizations.delete(locale)
  end
end

# Creates a list of available locales.
def discover_locales
  # Locales listed without a "-" match all variants.
  # Locales listed with a "-" match only those exact ones.
  ignored_locales = [
    # English is our fallback, we don't need another.
    "und",
    # Esperanto, Interlingua, Volapuk are made up languages.
    "eo", "ia", "vo",
    # Belarus (Classical orthography), Church Slavic, Manx, Prussian are historical.
    "be-tarask", "cu", "gv", "prg",
    # Valencian differs from its parent only by a single character (è/é).
    "ca-ES-valencia",
    # Africa secondary languages.
    "bm", "byn", "dje", "dyo", "ff", "ha", "shi", "vai", "wo", "yo",
    # Infrequently used locales.
    "jv", "kn", "row", "sat", "sd", "to",
  ]

  Dir.entries(LOCALE_DIR).inject([]) do |locales, entry|
    next locales if entry.start_with?(".")

    entry_parts = entry.split("-")
    next locales if ignored_locales.include?(entry) || ignored_locales.include?(entry_parts[0])

    locales << entry
  end
end

# Prepares the currencies for a specific country.
def prepare_currencies(currencies)
  return {} if currencies.nil?

  # Rekey the array by currency code.
  currencies = currencies.each_with_index.inject({}) do |currencies, (real_currencies, index)|
    real_currencies.each_with_object(currencies) do |(currency_code, currency), currencies|
      currencies[currency_code] = currency
    end
  end

  # Remove non-tender currencies.
  currencies = currencies.delete_if { |_, currency| currency.key?("_tender") && currency["_tender"] == "false" }

  # Sort by _from date.
  currencies = currencies.sort do |a, b|
    a = DateTime.parse(a[1]["_from"])
    b = DateTime.parse(b[1]["_from"])

    if a == b
      0
    else
      (a < b ? -1 : 1)
    end
  end

  currencies.to_h
end

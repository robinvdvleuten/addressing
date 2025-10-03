# frozen_string_literal: true

module Addressing
  # Provides country information including names, codes, currency, and timezones.
  #
  # Country names are available in over 250 locales powered by CLDR data.
  #
  # @example Get a country by code
  #   brazil = Addressing::Country.get('BR')
  #   brazil.name          # => "Brazil"
  #   brazil.currency_code # => "BRL"
  #
  # @example Get all countries
  #   countries = Addressing::Country.all('fr-FR')
  #
  # @example Get a simple list of countries
  #   list = Addressing::Country.list('en')
  class Country
    class << self
      AVAILABLE_LOCALES = [
        "af", "am", "ar", "ar-LY", "ar-SA", "as", "az", "be", "bg", "bn",
        "bn-IN", "bs", "ca", "chr", "cs", "cy", "da", "de", "de-AT", "de-CH",
        "dsb", "el", "el-polyton", "en", "en-001", "en-AU", "en-CA", "en-ID",
        "en-MV", "es", "es-419", "es-AR", "es-BO", "es-CL", "es-CO", "es-CR",
        "es-DO", "es-EC", "es-GT", "es-HN", "es-MX", "es-NI", "es-PA", "es-PE",
        "es-PR", "es-PY", "es-SV", "es-US", "es-VE", "et", "eu", "fa", "fa-AF",
        "fi", "fil", "fr", "fr-BE", "fr-CA", "ga", "gd", "gl", "gu", "he",
        "hi", "hi-Latn", "hr", "hsb", "hu", "hy", "id", "ig", "is", "it", "ja",
        "ka", "kk", "km", "ko", "ko-KP", "kok", "ky", "lo", "lt", "lv", "mk",
        "ml", "mn", "mr", "ms", "my", "ne", "nl", "nn", "no", "or", "pa", "pl",
        "ps", "ps-PK", "pt", "pt-PT", "ro", "ro-MD", "ru", "ru-UA", "si", "sk",
        "sl", "so", "sq", "sr", "sr-Cyrl-BA", "sr-Cyrl-ME", "sr-Cyrl-XK",
        "sr-Latn", "sr-Latn-BA", "sr-Latn-ME", "sr-Latn-XK", "sv", "sw",
        "sw-CD", "sw-KE", "ta", "te", "th", "tk", "tr", "uk", "ur", "ur-IN",
        "uz", "vi", "yue", "yue-Hans", "zh", "zh-Hant", "zh-Hant-HK", "zu"
      ]

      # Gets a Country instance for the provided country code.
      #
      # @param country_code [String] ISO 3166-1 alpha-2 country code
      # @param locale [String] Locale for the country name (default: "en")
      # @param fallback_locale [String] Fallback locale if requested locale is unavailable
      # @return [Country] Country instance
      # @raise [UnknownCountryError] if the country code is not recognized
      def get(country_code, locale = "en", fallback_locale = "en")
        country_code = country_code.upcase

        raise UnknownCountryError.new(country_code) unless base_definitions.key?(country_code)

        locale = Locale.resolve(AVAILABLE_LOCALES, locale, fallback_locale)
        definitions = load_definitions(locale)

        new(
          country_code: country_code,
          name: definitions[country_code],
          three_letter_code: base_definitions[country_code][0],
          numeric_code: base_definitions[country_code][1],
          currency_code: base_definitions[country_code][2],
          locale: locale
        )
      end

      # Gets all Country instances.
      #
      # @param locale [String] Locale for country names (default: "en")
      # @param fallback_locale [String] Fallback locale if requested locale is unavailable
      # @return [Hash<String, Country>] Hash of country code => Country instance
      def all(locale = "en", fallback_locale = "en")
        locale = Locale.resolve(AVAILABLE_LOCALES, locale, fallback_locale)
        definitions = load_definitions(locale)

        definitions.map do |country_code, country_name|
          country = new(
            country_code: country_code,
            name: country_name,
            three_letter_code: base_definitions[country_code][0],
            numeric_code: base_definitions[country_code][1],
            currency_code: base_definitions[country_code][2],
            locale: locale
          )

          [country_code, country]
        end.to_h
      end

      # Gets a list of country codes and names.
      #
      # @param locale [String] Locale for country names (default: "en")
      # @param fallback_locale [String] Fallback locale if requested locale is unavailable
      # @return [Hash<String, String>] Hash of country code => country name
      def list(locale = "en", fallback_locale = "en")
        locale = Locale.resolve(AVAILABLE_LOCALES, locale, fallback_locale)
        definitions = load_definitions(locale)

        definitions.map do |country_code, country_name|
          [country_code, country_name]
        end.to_h
      end

      protected

      # Loads the country definitions for the provided locale.
      def load_definitions(locale)
        @definitions ||= {}
        unless @definitions.key?(locale)
          filename = File.join(File.expand_path("../../../data/country", __FILE__).to_s, "#{locale}.json")
          @definitions[locale] = JSON.parse(File.read(filename))
        end

        @definitions[locale]
      end

      # Gets the base country definitions.
      #
      # Contains data common to all locales: three letter code, numeric code.
      def base_definitions
        @base_definitions ||= {
          "AC" => ["ASC", nil, "SHP"],
          "AD" => ["AND", "020", "EUR"],
          "AE" => ["ARE", "784", "AED"],
          "AF" => ["AFG", "004", "AFN"],
          "AG" => ["ATG", "028", "XCD"],
          "AI" => ["AIA", "660", "XCD"],
          "AL" => ["ALB", "008", "ALL"],
          "AM" => ["ARM", "051", "AMD"],
          "AO" => ["AGO", "024", "AOA"],
          "AQ" => ["ATA", "010", nil],
          "AR" => ["ARG", "032", "ARS"],
          "AS" => ["ASM", "016", "USD"],
          "AT" => ["AUT", "040", "EUR"],
          "AU" => ["AUS", "036", "AUD"],
          "AW" => ["ABW", "533", "AWG"],
          "AX" => ["ALA", "248", "EUR"],
          "AZ" => ["AZE", "031", "AZN"],
          "BA" => ["BIH", "070", "BAM"],
          "BB" => ["BRB", "052", "BBD"],
          "BD" => ["BGD", "050", "BDT"],
          "BE" => ["BEL", "056", "EUR"],
          "BF" => ["BFA", "854", "XOF"],
          "BG" => ["BGR", "100", "BGN"],
          "BH" => ["BHR", "048", "BHD"],
          "BI" => ["BDI", "108", "BIF"],
          "BJ" => ["BEN", "204", "XOF"],
          "BL" => ["BLM", "652", "EUR"],
          "BM" => ["BMU", "060", "BMD"],
          "BN" => ["BRN", "096", "BND"],
          "BO" => ["BOL", "068", "BOB"],
          "BQ" => ["BES", "535", "USD"],
          "BR" => ["BRA", "076", "BRL"],
          "BS" => ["BHS", "044", "BSD"],
          "BT" => ["BTN", "064", "BTN"],
          "BV" => ["BVT", "074", "NOK"],
          "BW" => ["BWA", "072", "BWP"],
          "BY" => ["BLR", "112", "BYN"],
          "BZ" => ["BLZ", "084", "BZD"],
          "CA" => ["CAN", "124", "CAD"],
          "CC" => ["CCK", "166", "AUD"],
          "CD" => ["COD", "180", "CDF"],
          "CF" => ["CAF", "140", "XAF"],
          "CG" => ["COG", "178", "XAF"],
          "CH" => ["CHE", "756", "CHF"],
          "CI" => ["CIV", "384", "XOF"],
          "CK" => ["COK", "184", "NZD"],
          "CL" => ["CHL", "152", "CLP"],
          "CM" => ["CMR", "120", "XAF"],
          "CN" => ["CHN", "156", "CNY"],
          "CO" => ["COL", "170", "COP"],
          "CP" => ["CPT", nil, nil],
          "CR" => ["CRI", "188", "CRC"],
          "CU" => ["CUB", "192", "CUP"],
          "CV" => ["CPV", "132", "CVE"],
          "CW" => ["CUW", "531", "XCG"],
          "CX" => ["CXR", "162", "AUD"],
          "CY" => ["CYP", "196", "EUR"],
          "CZ" => ["CZE", "203", "CZK"],
          "DE" => ["DEU", "276", "EUR"],
          "DG" => ["DGA", nil, "USD"],
          "DJ" => ["DJI", "262", "DJF"],
          "DK" => ["DNK", "208", "DKK"],
          "DM" => ["DMA", "212", "XCD"],
          "DO" => ["DOM", "214", "DOP"],
          "DZ" => ["DZA", "012", "DZD"],
          "EA" => [nil, nil, "EUR"],
          "EC" => ["ECU", "218", "USD"],
          "EE" => ["EST", "233", "EUR"],
          "EG" => ["EGY", "818", "EGP"],
          "EH" => ["ESH", "732", "MAD"],
          "ER" => ["ERI", "232", "ERN"],
          "ES" => ["ESP", "724", "EUR"],
          "ET" => ["ETH", "231", "ETB"],
          "FI" => ["FIN", "246", "EUR"],
          "FJ" => ["FJI", "242", "FJD"],
          "FK" => ["FLK", "238", "FKP"],
          "FM" => ["FSM", "583", "USD"],
          "FO" => ["FRO", "234", "DKK"],
          "FR" => ["FRA", "250", "EUR"],
          "GA" => ["GAB", "266", "XAF"],
          "GB" => ["GBR", "826", "GBP"],
          "GD" => ["GRD", "308", "XCD"],
          "GE" => ["GEO", "268", "GEL"],
          "GF" => ["GUF", "254", "EUR"],
          "GG" => ["GGY", "831", "GBP"],
          "GH" => ["GHA", "288", "GHS"],
          "GI" => ["GIB", "292", "GIP"],
          "GL" => ["GRL", "304", "DKK"],
          "GM" => ["GMB", "270", "GMD"],
          "GN" => ["GIN", "324", "GNF"],
          "GP" => ["GLP", "312", "EUR"],
          "GQ" => ["GNQ", "226", "XAF"],
          "GR" => ["GRC", "300", "EUR"],
          "GS" => ["SGS", "239", "GBP"],
          "GT" => ["GTM", "320", "GTQ"],
          "GU" => ["GUM", "316", "USD"],
          "GW" => ["GNB", "624", "XOF"],
          "GY" => ["GUY", "328", "GYD"],
          "HK" => ["HKG", "344", "HKD"],
          "HM" => ["HMD", "334", "AUD"],
          "HN" => ["HND", "340", "HNL"],
          "HR" => ["HRV", "191", "EUR"],
          "HT" => ["HTI", "332", "USD"],
          "HU" => ["HUN", "348", "HUF"],
          "IC" => [nil, nil, "EUR"],
          "ID" => ["IDN", "360", "IDR"],
          "IE" => ["IRL", "372", "EUR"],
          "IL" => ["ISR", "376", "ILS"],
          "IM" => ["IMN", "833", "GBP"],
          "IN" => ["IND", "356", "INR"],
          "IO" => ["IOT", "086", "USD"],
          "IQ" => ["IRQ", "368", "IQD"],
          "IR" => ["IRN", "364", "IRR"],
          "IS" => ["ISL", "352", "ISK"],
          "IT" => ["ITA", "380", "EUR"],
          "JE" => ["JEY", "832", "GBP"],
          "JM" => ["JAM", "388", "JMD"],
          "JO" => ["JOR", "400", "JOD"],
          "JP" => ["JPN", "392", "JPY"],
          "KE" => ["KEN", "404", "KES"],
          "KG" => ["KGZ", "417", "KGS"],
          "KH" => ["KHM", "116", "KHR"],
          "KI" => ["KIR", "296", "AUD"],
          "KM" => ["COM", "174", "KMF"],
          "KN" => ["KNA", "659", "XCD"],
          "KP" => ["PRK", "408", "KPW"],
          "KR" => ["KOR", "410", "KRW"],
          "KW" => ["KWT", "414", "KWD"],
          "KY" => ["CYM", "136", "KYD"],
          "KZ" => ["KAZ", "398", "KZT"],
          "LA" => ["LAO", "418", "LAK"],
          "LB" => ["LBN", "422", "LBP"],
          "LC" => ["LCA", "662", "XCD"],
          "LI" => ["LIE", "438", "CHF"],
          "LK" => ["LKA", "144", "LKR"],
          "LR" => ["LBR", "430", "LRD"],
          "LS" => ["LSO", "426", "LSL"],
          "LT" => ["LTU", "440", "EUR"],
          "LU" => ["LUX", "442", "EUR"],
          "LV" => ["LVA", "428", "EUR"],
          "LY" => ["LBY", "434", "LYD"],
          "MA" => ["MAR", "504", "MAD"],
          "MC" => ["MCO", "492", "EUR"],
          "MD" => ["MDA", "498", "MDL"],
          "ME" => ["MNE", "499", "EUR"],
          "MF" => ["MAF", "663", "EUR"],
          "MG" => ["MDG", "450", "MGA"],
          "MH" => ["MHL", "584", "USD"],
          "MK" => ["MKD", "807", "MKD"],
          "ML" => ["MLI", "466", "XOF"],
          "MM" => ["MMR", "104", "MMK"],
          "MN" => ["MNG", "496", "MNT"],
          "MO" => ["MAC", "446", "MOP"],
          "MP" => ["MNP", "580", "USD"],
          "MQ" => ["MTQ", "474", "EUR"],
          "MR" => ["MRT", "478", "MRU"],
          "MS" => ["MSR", "500", "XCD"],
          "MT" => ["MLT", "470", "EUR"],
          "MU" => ["MUS", "480", "MUR"],
          "MV" => ["MDV", "462", "MVR"],
          "MW" => ["MWI", "454", "MWK"],
          "MX" => ["MEX", "484", "MXN"],
          "MY" => ["MYS", "458", "MYR"],
          "MZ" => ["MOZ", "508", "MZN"],
          "NA" => ["NAM", "516", "NAD"],
          "NC" => ["NCL", "540", "XPF"],
          "NE" => ["NER", "562", "XOF"],
          "NF" => ["NFK", "574", "AUD"],
          "NG" => ["NGA", "566", "NGN"],
          "NI" => ["NIC", "558", "NIO"],
          "NL" => ["NLD", "528", "EUR"],
          "NO" => ["NOR", "578", "NOK"],
          "NP" => ["NPL", "524", "NPR"],
          "NR" => ["NRU", "520", "AUD"],
          "NU" => ["NIU", "570", "NZD"],
          "NZ" => ["NZL", "554", "NZD"],
          "OM" => ["OMN", "512", "OMR"],
          "PA" => ["PAN", "591", "USD"],
          "PE" => ["PER", "604", "PEN"],
          "PF" => ["PYF", "258", "XPF"],
          "PG" => ["PNG", "598", "PGK"],
          "PH" => ["PHL", "608", "PHP"],
          "PK" => ["PAK", "586", "PKR"],
          "PL" => ["POL", "616", "PLN"],
          "PM" => ["SPM", "666", "EUR"],
          "PN" => ["PCN", "612", "NZD"],
          "PR" => ["PRI", "630", "USD"],
          "PS" => ["PSE", "275", "JOD"],
          "PT" => ["PRT", "620", "EUR"],
          "PW" => ["PLW", "585", "USD"],
          "PY" => ["PRY", "600", "PYG"],
          "QA" => ["QAT", "634", "QAR"],
          "RE" => ["REU", "638", "EUR"],
          "RO" => ["ROU", "642", "RON"],
          "RS" => ["SRB", "688", "RSD"],
          "RU" => ["RUS", "643", "RUB"],
          "RW" => ["RWA", "646", "RWF"],
          "SA" => ["SAU", "682", "SAR"],
          "SB" => ["SLB", "090", "SBD"],
          "SC" => ["SYC", "690", "SCR"],
          "SD" => ["SDN", "729", "SDG"],
          "SE" => ["SWE", "752", "SEK"],
          "SG" => ["SGP", "702", "SGD"],
          "SH" => ["SHN", "654", "SHP"],
          "SI" => ["SVN", "705", "EUR"],
          "SJ" => ["SJM", "744", "NOK"],
          "SK" => ["SVK", "703", "EUR"],
          "SL" => ["SLE", "694", "SLE"],
          "SM" => ["SMR", "674", "EUR"],
          "SN" => ["SEN", "686", "XOF"],
          "SO" => ["SOM", "706", "SOS"],
          "SR" => ["SUR", "740", "SRD"],
          "SS" => ["SSD", "728", "SSP"],
          "ST" => ["STP", "678", "STN"],
          "SV" => ["SLV", "222", "USD"],
          "SX" => ["SXM", "534", "XCG"],
          "SY" => ["SYR", "760", "SYP"],
          "SZ" => ["SWZ", "748", "SZL"],
          "TA" => ["TAA", nil, "GBP"],
          "TC" => ["TCA", "796", "USD"],
          "TD" => ["TCD", "148", "XAF"],
          "TF" => ["ATF", "260", "EUR"],
          "TG" => ["TGO", "768", "XOF"],
          "TH" => ["THA", "764", "THB"],
          "TJ" => ["TJK", "762", "TJS"],
          "TK" => ["TKL", "772", "NZD"],
          "TL" => ["TLS", "626", "USD"],
          "TM" => ["TKM", "795", "TMT"],
          "TN" => ["TUN", "788", "TND"],
          "TO" => ["TON", "776", "TOP"],
          "TR" => ["TUR", "792", "TRY"],
          "TT" => ["TTO", "780", "TTD"],
          "TV" => ["TUV", "798", "AUD"],
          "TW" => ["TWN", "158", "TWD"],
          "TZ" => ["TZA", "834", "TZS"],
          "UA" => ["UKR", "804", "UAH"],
          "UG" => ["UGA", "800", "UGX"],
          "UM" => ["UMI", "581", "USD"],
          "US" => ["USA", "840", "USD"],
          "UY" => ["URY", "858", "UYU"],
          "UZ" => ["UZB", "860", "UZS"],
          "VA" => ["VAT", "336", "EUR"],
          "VC" => ["VCT", "670", "XCD"],
          "VE" => ["VEN", "862", "VES"],
          "VG" => ["VGB", "092", "USD"],
          "VI" => ["VIR", "850", "USD"],
          "VN" => ["VNM", "704", "VND"],
          "VU" => ["VUT", "548", "VUV"],
          "WF" => ["WLF", "876", "XPF"],
          "WS" => ["WSM", "882", "WST"],
          "XK" => ["XKK", "983", "EUR"],
          "YE" => ["YEM", "887", "YER"],
          "YT" => ["MYT", "175", "EUR"],
          "ZA" => ["ZAF", "710", "ZAR"],
          "ZM" => ["ZMB", "894", "ZMW"],
          "ZW" => ["ZWE", "716", "ZWG"]
        }
      end
    end

    attr_reader :country_code, :name, :three_letter_code, :numeric_code, :currency_code, :locale

    def initialize(definition = {})
      # Validate the presence of required properties.
      [:country_code, :name, :locale].each do |required_property|
        if definition[required_property].nil?
          raise ArgumentError, "Missing required property #{required_property}."
        end
      end

      @country_code = definition[:country_code]
      @name = definition[:name]
      @three_letter_code = definition[:three_letter_code]
      @numeric_code = definition[:numeric_code]
      @currency_code = definition[:currency_code]
      @locale = definition[:locale]
    end

    # Gets the timezones.
    #
    # Note that a country can span more than one timezone.
    # For example, Germany has ["Europe/Berlin", "Europe/Busingen"].
    def timezones
      @timezones ||= TZInfo::Country.get(@country_code).zone_identifiers
    end

    # Gets the string representation of the Country.
    def to_s
      @country_code
    end
  end
end

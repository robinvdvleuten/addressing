# frozen_string_literal: true

module Addressing
  class Locale
    ALIASES = {
      "az-AZ" => "az-Latn-AZ",
      "bs-BA" => "bs-Latn-BA",
      "ha-GH" => "ha-Latn-GH",
      "ha-NE" => "ha-Latn-NE",
      "ha-NG" => "ha-Latn-NG",
      "in" => "id",
      "in-ID" => "id-ID",
      "iw" => "he",
      "iw-IL" => "he-IL",
      "kk-KZ" => "kk-Cyrl-KZ",
      "ks-IN" => "ks-Arab-IN",
      "ky-KG" => "ky-Cyrl-KG",
      "mn-MN" => "mn-Cyrl-MN",
      "mo" => "ro-MD",
      "ms-BN" => "ms-Latn-BN",
      "ms-MY" => "ms-Latn-MY",
      "ms-SG" => "ms-Latn-SG",
      "no" => "nb",
      "no-NO" => "nb-NO",
      "no-NO-NY" => "nn-NO",
      "pa-IN" => "pa-Guru-IN",
      "pa-PK" => "pa-Arab-PK",
      "sh" => "sr-Latn",
      "sh-BA" => "sr-Latn-BA",
      "sh-CS" => "sr-Latn-RS",
      "sh-YU" => "sr-Latn-RS",
      "shi-MA" => "shi-Tfng-MA",
      "sr-BA" => "sr-Cyrl-BA",
      "sr-ME" => "sr-Latn-ME",
      "sr-RS" => "sr-Cyrl-RS",
      "sr-XK" => "sr-Cyrl-XK",
      "tl" => "fil",
      "tl-PH" => "fil-PH",
      "tzm-MA" => "tzm-Latn-MA",
      "ug-CN" => "ug-Arab-CN",
      "uz-AF" => "uz-Arab-AF",
      "uz-UZ" => "uz-Latn-UZ",
      "vai-LR" => "vai-Vaii-LR",
      "zh-CN" => "zh-Hans-CN",
      "zh-HK" => "zh-Hant-HK",
      "zh-MO" => "zh-Hant-MO",
      "zh-SG" => "zh-Hans-SG",
      "zh-TW" => "zh-Hant-TW"
    }.freeze

    PARENTS = {
      "en-150" => "en-001",
      "en-AG" => "en-001",
      "en-AI" => "en-001",
      "en-AU" => "en-001",
      "en-BB" => "en-001",
      "en-BM" => "en-001",
      "en-BS" => "en-001",
      "en-BW" => "en-001",
      "en-BZ" => "en-001",
      "en-CC" => "en-001",
      "en-CK" => "en-001",
      "en-CM" => "en-001",
      "en-CX" => "en-001",
      "en-CY" => "en-001",
      "en-DG" => "en-001",
      "en-DM" => "en-001",
      "en-ER" => "en-001",
      "en-FJ" => "en-001",
      "en-FK" => "en-001",
      "en-FM" => "en-001",
      "en-GB" => "en-001",
      "en-GD" => "en-001",
      "en-GG" => "en-001",
      "en-GH" => "en-001",
      "en-GI" => "en-001",
      "en-GM" => "en-001",
      "en-GY" => "en-001",
      "en-HK" => "en-001",
      "en-IE" => "en-001",
      "en-IL" => "en-001",
      "en-IM" => "en-001",
      "en-IN" => "en-001",
      "en-IO" => "en-001",
      "en-JE" => "en-001",
      "en-JM" => "en-001",
      "en-KE" => "en-001",
      "en-KI" => "en-001",
      "en-KN" => "en-001",
      "en-KY" => "en-001",
      "en-LC" => "en-001",
      "en-LR" => "en-001",
      "en-LS" => "en-001",
      "en-MG" => "en-001",
      "en-MO" => "en-001",
      "en-MS" => "en-001",
      "en-MT" => "en-001",
      "en-MU" => "en-001",
      "en-MW" => "en-001",
      "en-MY" => "en-001",
      "en-NA" => "en-001",
      "en-NF" => "en-001",
      "en-NG" => "en-001",
      "en-NR" => "en-001",
      "en-NU" => "en-001",
      "en-NZ" => "en-001",
      "en-PG" => "en-001",
      "en-PK" => "en-001",
      "en-PN" => "en-001",
      "en-PW" => "en-001",
      "en-RW" => "en-001",
      "en-SB" => "en-001",
      "en-SC" => "en-001",
      "en-SD" => "en-001",
      "en-SG" => "en-001",
      "en-SH" => "en-001",
      "en-SL" => "en-001",
      "en-SS" => "en-001",
      "en-SX" => "en-001",
      "en-SZ" => "en-001",
      "en-TC" => "en-001",
      "en-TK" => "en-001",
      "en-TO" => "en-001",
      "en-TT" => "en-001",
      "en-TV" => "en-001",
      "en-TZ" => "en-001",
      "en-UG" => "en-001",
      "en-VC" => "en-001",
      "en-VG" => "en-001",
      "en-VU" => "en-001",
      "en-WS" => "en-001",
      "en-ZA" => "en-001",
      "en-ZM" => "en-001",
      "en-ZW" => "en-001",
      "en-AT" => "en-150",
      "en-BE" => "en-150",
      "en-CH" => "en-150",
      "en-DE" => "en-150",
      "en-DK" => "en-150",
      "en-FI" => "en-150",
      "en-NL" => "en-150",
      "en-SE" => "en-150",
      "en-SI" => "en-150",
      "es-AR" => "es-419",
      "es-BO" => "es-419",
      "es-BR" => "es-419",
      "es-BZ" => "es-419",
      "es-CL" => "es-419",
      "es-CO" => "es-419",
      "es-CR" => "es-419",
      "es-CU" => "es-419",
      "es-DO" => "es-419",
      "es-EC" => "es-419",
      "es-GT" => "es-419",
      "es-HN" => "es-419",
      "es-MX" => "es-419",
      "es-NI" => "es-419",
      "es-PA" => "es-419",
      "es-PE" => "es-419",
      "es-PR" => "es-419",
      "es-PY" => "es-419",
      "es-SV" => "es-419",
      "es-US" => "es-419",
      "es-UY" => "es-419",
      "es-VE" => "es-419",
      "nb" => "no",
      "nn" => "no",
      "pt-AO" => "pt-PT",
      "pt-CH" => "pt-PT",
      "pt-CV" => "pt-PT",
      "pt-FR" => "pt-PT",
      "pt-GQ" => "pt-PT",
      "pt-GW" => "pt-PT",
      "pt-LU" => "pt-PT",
      "pt-MO" => "pt-PT",
      "pt-MZ" => "pt-PT",
      "pt-ST" => "pt-PT",
      "pt-TL" => "pt-PT",
      "az-Arab" => "und",
      "az-Cyrl" => "und",
      "bal-Latn" => "und",
      "blt-Latn" => "und",
      "bs-Cyrl" => "und",
      "byn-Latn" => "und",
      "en-Dsrt" => "und",
      "en-Shaw" => "und",
      "hi-Latn" => "und",
      "iu-Latn" => "und",
      "kk-Arab" => "und",
      "ks-Deva" => "und",
      "ku-Arab" => "und",
      "ky-Arab" => "und",
      "ky-Latn" => "und",
      "ml-Arab" => "und",
      "mn-Mong" => "und",
      "mni-Mtei" => "und",
      "ms-Arab" => "und",
      "pa-Arab" => "und",
      "sat-Deva" => "und",
      "sd-Deva" => "und",
      "sd-Khoj" => "und",
      "sd-Sind" => "und",
      "so-Arab" => "und",
      "sr-Latn" => "und",
      "sw-Arab" => "und",
      "tg-Arab" => "und",
      "uz-Arab" => "und",
      "uz-Cyrl" => "und",
      "yue-Hans" => "und",
      "zh-Hant" => "und",
      "zh-Hant-MO" => "zh-Hant-HK"
    }.freeze

    # Checks whether two locales match.
    def self.match(first_locale, second_locale)
      return false if first_locale.to_s.empty? || second_locale.to_s.empty?

      canonicalize(first_locale) == canonicalize(second_locale)
    end

    # Checks whether two locales have at least one common candidate.
    #
    # For example, "de" and "de-AT" will match because they both have
    # "de" in common. This is useful for partial locale matching.
    def self.match_candidates(first_locale, second_locale)
      return false if first_locale.to_s.empty? || second_locale.to_s.empty?

      first_locale = canonicalize(first_locale)
      second_locale = canonicalize(second_locale)
      first_locale_candidates = candidates(first_locale)
      second_locale_candidates = candidates(second_locale)

      (first_locale_candidates & second_locale_candidates).any?
    end

    # Resolves the locale from the available locales.
    #
    # Takes all locale candidates for the requested locale
    # and fallback locale, searches for them in the available
    # locale list. The first found locale is returned.
    # If no candidate is found in the list, an error is raised.
    def self.resolve(available_locales, locale, fallback_locale = nil)
      locale = canonicalize(locale)
      resolved_locale = nil

      candidates(locale, fallback_locale).each do |candidate|
        if available_locales.include?(candidate)
          resolved_locale = candidate
          break
        end
      end

      # No locale could be resolved, stop here.
      raise UnknownLocaleError, locale if resolved_locale.nil?

      resolved_locale
    end

    # Canonicalizes the given locale.
    #
    # Standardizes separators and capitalization, turning
    # a locale such as "sr_rs_latn" into "sr-RS-Latn".
    def self.canonicalize(locale)
      return locale if locale.to_s.empty?

      # Lowercase the locale and replace all dashes with underscores.
      locale_parts = locale.downcase.tr("_", "-").split("-")

      locale_parts.map.with_index do |part, index|
        # The language code should stay lowercase.
        next part if index == 0

        if part.length == 4
          # Script code.
          next part.capitalize
        end

        # Country or variant code.
        part.upcase
      end.join("-")
    end

    # Gets locale candidates.
    #
    # For example, "bs-Cyrl-BA" has the following candidates:
    # 1) bs-Cyrl-BA
    # 2) bs-Cyrl
    # 3) bs
    #
    # The locale is de-aliased, e.g. the candidates for "sh" are:
    # 1) sr-Latn
    # 2) sr
    def self.candidates(locale, fallback_locale = nil)
      locale = replace_alias(locale)
      candidates = [locale]

      while (parent = parent(locale))
        candidates << parent
        locale = parent
      end

      if fallback_locale
        candidates << fallback_locale

        while (parent = parent(fallback_locale))
          candidates << parent
          fallback_locale = parent
        end
      end

      candidates.uniq
    end

    # Gets the parent for the given locale.
    def self.parent(locale)
      parent = nil

      if PARENTS.key?(locale)
        parent = PARENTS[locale]
      elsif locale.include?("-")
        locale_parts = locale.split("-")
        locale_parts.pop
        parent = locale_parts.join("-")
      end

      # The library doesn't have data for the empty `und` locale, it
      # is more user friendly to use the configured fallback instead.
      if parent == "und"
        parent = nil
      end

      parent
    end

    # Replaces a locale alias with the real locale.
    #
    # For example, "zh-CN" is replaced with "zh-Hans-CN".
    def self.replace_alias(locale)
      return locale if locale.to_s.empty? || !ALIASES.key?(locale)

      ALIASES[locale]
    end
  end
end

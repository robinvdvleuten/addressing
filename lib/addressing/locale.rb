# frozen_string_literal: true

module Addressing
  class Locale
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

      (candidates(canonicalize(first_locale)) & candidates(canonicalize(second_locale))).any?
    end

    # Resolves the locale from the available locales.
    #
    # Takes all locale candidates for the requested locale
    # and fallback locale, searches for them in the available
    # locale list. The first found locale is returned.
    # If no candidate is found in the list, an error is raised.
    def self.resolve(available_locales, locale, fallback_locale = nil)
      locale = canonicalize(locale)
      resolved_locale = candidates(locale, fallback_locale).find { |candidate| available_locales.include?(candidate) }

      # No locale could be resolved, stop here.
      raise UnknownLocaleError.new(locale) if resolved_locale.nil?

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
      candidates = lineage(replace_alias(locale))
      candidates += lineage(fallback_locale) if fallback_locale
      candidates.uniq
    end

    # Gets the given locale followed by its parents.
    def self.lineage(locale)
      lineage = [locale]
      lineage << locale while (locale = parent(locale))
      lineage
    end
    private_class_method :lineage

    # Gets the parent for the given locale.
    def self.parent(locale)
      parent = definitions["parents"].fetch(locale) { locale.include?("-") ? locale.rpartition("-").first : nil }

      # The library doesn't have data for the empty `und` locale, it
      # is more user friendly to use the configured fallback instead.
      (parent == "und") ? nil : parent
    end

    # Replaces a locale alias with the real locale.
    #
    # For example, "zh-CN" is replaced with "zh-Hans-CN".
    def self.replace_alias(locale)
      definitions["aliases"].fetch(locale, locale)
    end

    # Gets the locale aliases and parents.
    def self.definitions
      Addressing.data_source.fetch("locale")
    end
    private_class_method :definitions
  end
end

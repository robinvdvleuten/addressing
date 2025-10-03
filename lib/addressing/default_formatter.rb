# frozen_string_literal: true

module Addressing
  class DefaultFormatter
    DEFAULT_LOCALE = "en"
    FORMAT_PLACEHOLDER_PATTERN = /%[a-z1-9_]+/
    LEADING_TRAILING_PUNCTUATION_PATTERN = /\A[ \-,]+|[ \-,]+\z/
    MULTIPLE_SPACES_PATTERN = /\s\s+/

    DEFAULT_OPTIONS = {
      locale: DEFAULT_LOCALE,
      html: true,
      html_tag: "p",
      html_attributes: {translate: "no"}
    }

    def initialize(default_options = {})
      assert_options(default_options)

      @default_options = self.class::DEFAULT_OPTIONS.merge(default_options)
      @country_list_cache = {}
    end

    def format(address, options = {})
      assert_options(options)

      options = @default_options.merge(options)
      address_format = AddressFormat.get(address.country_code)

      # Add the country to the bottom or the top of the format string,
      # depending on whether the format is minor-to-major or major-to-minor.
      format_string = if Locale.match_candidates(address_format.locale, address.locale)
        "%country\n" + address_format.local_format
      else
        address_format.format + "\n%country"
      end

      view = build_view(address, address_format, options)
      view = render_view(view)

      replacements = view.map { |key, element| ["%#{key}", element] }.to_h
      output = format_string.gsub(FORMAT_PLACEHOLDER_PATTERN) { |m| replacements[m] }
      output = clean_output(output)

      if options[:html]
        output = output.gsub("\n", "<br>\n")
        # Add the HTML wrapper element.
        output = render_html_element(value: "\n#{output}\n", html_tag: options[:html_tag], html_attributes: options[:html_attributes])
      end

      output
    end

    protected

    # Builds the view for the given address.
    def build_view(address, address_format, options)
      countries = country_list(options[:locale])
      values = values(address, address_format).merge({"country" => countries.key?(address.country_code) ? countries[address.country_code] : address.country_code})
      used_fields = address_format.used_fields + ["country"]

      used_fields.map do |field|
        [field, {html: options[:html], html_tag: "span", html_attributes: {class: field.tr("_", "-")}, value: values[field]}]
      end.to_h
    end

    # Gets the country list for a locale, with caching.
    def country_list(locale)
      @country_list_cache[locale] ||= Country.list(locale)
    end

    # Renders the given view.
    def render_view(view)
      view.map do |key, element|
        next [key, ""] if element[:value].empty?

        if element[:html]
          element[:value] = CGI.escapeHTML(element[:value])
          next [key, render_html_element(element)]
        end

        [key, element[:value].gsub(/<\/?[^>]*>/, "")]
      end.to_h
    end

    def render_html_element(element)
      attributes = render_html_attributes(element[:html_attributes])

      "<#{element[:html_tag]} #{attributes}>#{element[:value]}</#{element[:html_tag]}>"
    end

    def render_html_attributes(attributes)
      attributes.map do |name, value|
        if value.is_a?(Array)
          value = value.join(" ")
        end

        "#{name}=\"#{CGI.escapeHTML(value)}\""
      end.join(" ")
    end

    # Removes empty lines, leading punctuation, excess whitespace.
    def clean_output(output)
      output.split("\n").map { |line| line.gsub(LEADING_TRAILING_PUNCTUATION_PATTERN, "").strip.gsub(MULTIPLE_SPACES_PATTERN, " ") }.reject(&:empty?).join("\n")
    end

    # Gets the address values used to build the view.
    def values(address, address_format)
      values = extract_address_values(address)
      resolve_subdivision_values(values, address, address_format)
      values
    end

    # Extracts all address field values.
    def extract_address_values(address)
      AddressField.all.map { |_, field| [field, address.send(field)] }.to_h
    end

    # Resolves subdivision values to their display codes.
    def resolve_subdivision_values(values, address, address_format)
      subdivision_fields = address_format.used_subdivision_fields

      # Replace the subdivision values with the names of any predefined ones.
      subdivision_fields.each_with_index.inject([{}, []]) do |(original_values, parents), (field, index)|
        # This level is empty, so there can be no sublevels.
        break if values[field].nil?

        parents << ((index > 0) ? original_values[subdivision_fields[index - 1]] : address.country_code)

        subdivision = Subdivision.get(values[field], parents)
        break if subdivision.nil?

        # Remember the original value so that it can be used for parents.
        original_values[field] = values[field]

        # Replace the value with the expected code.
        use_local_name = Locale.match_candidates(address.locale, subdivision.locale)
        values[field] = use_local_name ? subdivision.local_code : subdivision.code

        # The current subdivision has no children, stop.
        break unless subdivision.children?

        [original_values, parents]
      end
    end

    private

    # Validates the provided options.
    #
    # Ensures the absence of unknown keys, correct data types and values.
    def assert_options(options)
      options.each do |option, value|
        unless self.class::DEFAULT_OPTIONS.key?(option)
          raise ArgumentError, "Unrecognized option #{option}."
        end
      end

      if options.key?(:html) && ![true, false].include?(options[:html])
        raise ArgumentError, "The option `html` must be a boolean."
      end

      if options.key?(:html_attributes) && !options[:html_attributes].is_a?(Hash)
        raise ArgumentError, "The option `html_attributes` must be a hash."
      end
    end
  end
end

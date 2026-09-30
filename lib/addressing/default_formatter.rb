# frozen_string_literal: true

module Addressing
  class DefaultFormatter
    DEFAULT_LOCALE = "en"
    FORMAT_PLACEHOLDER_PATTERN = /%[a-z1-9_]+/
    FORMAT_SPLIT_PATTERN = /(#{FORMAT_PLACEHOLDER_PATTERN})/
    LEADING_TRAILING_PUNCTUATION_PATTERN = /\A[ \-,]+|[ \-,]+\z/
    MULTIPLE_SPACES_PATTERN = /\s\s+/
    HTML_TAG_PATTERN = /\A[a-z][a-z0-9-]*\z/i

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

      replacements = view.transform_keys { |key| "%#{key}" }
      output = insert_values(format_string, replacements)
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
      values = values(address, address_format).merge("country" => countries.fetch(address.country_code, address.country_code))
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
      view.transform_values do |element|
        next "" if element[:value].empty?

        if element[:html]
          element[:value] = CGI.escapeHTML(element[:value])
          next render_html_element(element)
        end

        element[:value].gsub(/<\/?[^>]*>/, "")
      end
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

    # Inserts the rendered address fields into the format string.
    #
    # Empty fields need special handling. When one falls between two values,
    # keep the separator before it and discard the one after it.
    def insert_values(format_string, replacements)
      format_string.split("\n", -1).map do |line|
        rendered = +""
        separator = ""
        skipped = false

        line.split(FORMAT_SPLIT_PATTERN, -1).each do |part|
          unless replacements.key?(part)
            # A separator before an empty field usually belongs to
            # the value that came before it, so keep that one.
            separator = part unless skipped
            next
          end

          if replacements[part].empty?
            skipped = true
            next
          end

          rendered << separator if !rendered.empty? || !skipped
          rendered << replacements[part]
          separator = ""
          skipped = false
        end

        rendered
      end.join("\n")
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
      AddressField.all.values.to_h { |field| [field, address.send(field)] }
    end

    # Replaces the subdivision values with the codes of any predefined ones.
    def resolve_subdivision_values(values, address, address_format)
      fields = address_format.subdivision_fields
      chain = Subdivision.chain(address.country_code, values.values_at(*fields))

      fields.zip(chain.subdivisions) do |field, subdivision|
        break if subdivision.nil?

        # Replace the value with the expected code.
        use_local_name = Locale.match_candidates(address.locale, subdivision.locale)
        values[field] = use_local_name ? subdivision.local_code : subdivision.code
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

      # The tag is written into the markup as is, so only allow a tag name.
      if options.key?(:html_tag) && !HTML_TAG_PATTERN.match?(options[:html_tag].to_s)
        raise ArgumentError, "The option `html_tag` must be an HTML tag name."
      end

      if options.key?(:locale) && !options[:locale].is_a?(String)
        raise ArgumentError, "The option `locale` must be a string."
      end
    end
  end
end

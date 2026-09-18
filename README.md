# Addressing

A Ruby library that knows how postal addresses are written in every country — which fields exist, in what order, what to call them, and which ones are required. Give it an address and a country code, and it produces a correctly formatted label or HTML block, validates the postal code, and tells your form whether to ask for a "State", a "Province", or a "Prefecture".

Most country-data gems give you a list of countries and their subdivisions. This one gives you the **address format** behind each of them, so a checkout form or shipping label built on it is correct in Japan and Brazil, not just in the US.

- **Address formats for 205 countries.** Field order, required fields, uppercasing rules, postal code patterns, and the right label for each field.
- **256 countries, translated into 148 locales.** Names, three-letter and numeric codes, currency, and timezones. Powered by [CLDR](http://cldr.unicode.org) v48.
- **Subdivisions for 63 countries.** Up to three levels (administrative area → locality → dependent locality), in both latin and local scripts (Okinawa / 沖縄県).
- **Zero runtime dependencies.** Pure Ruby 3.3+. Address formats load from a 52 KB marshalled index; the 3.6 MB of country and subdivision data is read lazily, per country, only when you ask for it.
- **Rails-ready.** A `validates_address_format` validator for Active Record, which runs only when an address field actually changed.
- **Immutable.** `Address` objects never mutate; `with_*` methods return copies.

```rb
formatter = Addressing::DefaultFormatter.new(html: false)

puts formatter.format(Addressing::Address.new(country_code: "US",
  administrative_area: "CA", locality: "Mountain View",
  postal_code: "94043", address_line1: "1098 Alta Ave"))
# 1098 Alta Ave
# Mountain View, CA 94043
# United States

puts formatter.format(Addressing::Address.new(country_code: "JP",
  administrative_area: "26", locality: "京都市南区",
  postal_code: "601-8213", address_line1: "九条町1", locale: "ja"), locale: "ja")
# 日本
# 〒601-8213
# 京都府京都市南区
# 九条町1
```

Same code, two countries, two completely different layouts — including the `〒` prefix and the reversed field order Japan uses.

Address formats and subdivisions were initially generated from [Google's Address Data Service](https://chromium-i18n.appspot.com/ssl-address), and are kept in sync with the PHP [commerceguys/addressing](https://github.com/commerceguys/addressing) library.

---

## Table of contents

- [Installation](#installation)
- [Addresses](#addresses)
- [Address formats](#address-formats)
- [Countries](#countries)
- [Subdivisions](#subdivisions)
- [Formatting addresses](#formatting-addresses)
- [Validating addresses](#validating-addresses)
- [Contributing](#contributing)

## Installation

Add the gem to your Gemfile:

```rb
gem "addressing"
```

Then install it:

```
bundle install
```

Requires Ruby 3.3 or newer. There are no other runtime dependencies — Active Record is only needed for the validator, and `tzinfo` only for `Country#timezones`.

## Addresses

The [Address](lib/addressing/address.rb) class represents a postal address. Field names follow the OASIS [eXtensible Address Language (xAL)](http://www.oasis-open.org/committees/ciq/download.shtml) standard:

`country_code`, `administrative_area`, `locality`, `dependent_locality`, `postal_code`, `sorting_code`, `address_line1`, `address_line2`, `address_line3`, `organization`, `given_name`, `additional_name`, `family_name`, `locale`.

```rb
address = Addressing::Address.new(
  country_code: "US",
  administrative_area: "CA",
  locality: "Mountain View",
  postal_code: "94043",
  address_line1: "1600 Amphitheatre Parkway",
  organization: "Google Inc.",
  given_name: "John",
  family_name: "Smith"
)
```

Addresses are immutable. The `with_*` methods return a modified copy and can be chained:

```rb
address = Addressing::Address.new
  .with_country_code("US")
  .with_administrative_area("CA")
  .with_locality("Mountain View")
  .with_address_line1("1098 Alta Ave")
```

## Address formats

The [AddressFormat](lib/addressing/address_format.rb) class describes how a country writes its addresses: which fields are used and in which order, which are required, which must be uppercased for mailing, what each field is called, the postal code pattern, and which fields have predefined subdivision data.

```rb
format = Addressing::AddressFormat.get("BR")

p format.required_fields
# ["address_line1", "administrative_area", "locality", "postal_code", "given_name", "family_name"]

p format.administrative_area_type  # "state"
p format.postal_code_type          # "postal"
p format.subdivision_fields        # ["administrative_area", "locality"]
```

Use `administrative_area_type`, `locality_type`, `dependent_locality_type`, and `postal_code_type` to label your form fields the way locals expect — "state" in Brazil, "prefecture" in Japan, "county" in Ireland.

## Countries

The [Country](lib/addressing/country.rb) class provides the country name, the numeric and three-letter codes, the official currency code when known, and the timezones the country spans.

```rb
brazil = Addressing::Country.get("BR")

p brazil.three_letter_code  # "BRA"
p brazil.name               # "Brazil"
p brazil.currency_code      # "BRL"

# Get all countries as a hash of country_code => Country.
countries = Addressing::Country.all

# Get a { country_code => name } list, in French — useful for a <select>.
p Addressing::Country.list("fr-FR")["BR"]  # "Brésil"

# Or a single country in another locale.
p Addressing::Country.get("BR", "fr-FR").name  # "Brésil"
```

> `Country#timezones` is backed by the [tzinfo](https://github.com/tzinfo/tzinfo) gem. Add `gem "tzinfo"` (and `tzinfo-data` on platforms without a system timezone database) if you use it.

```rb
require "tzinfo"
p brazil.timezones.first(2)  # ["America/Noronha", "America/Belem"]
```

## Subdivisions

The [Subdivision](lib/addressing/subdivision.rb) class provides the subdivision code used on an envelope (`CA` for California), the name shown to the user, the local code and name for countries using a non-latin script, and a postal code pattern when it differs from the country's.

Subdivisions are hierarchical, up to three levels: administrative area → locality → dependent locality. Pass the parents as an array.

```rb
# All Brazilian states.
states = Addressing::Subdivision.all(["BR"])
p states.size  # 27

# One state, by code.
ceara = Addressing::Subdivision.get("CE", ["BR"])
p [ceara.code, ceara.name, ceara.children?]  # ["CE", "Ceará", true]

# The municipalities of Ceará.
p Addressing::Subdivision.all(["BR", "CE"]).size  # 184

# A { code => name } list, ready for a <select>.
Addressing::Subdivision.list(["BR"])
```

Data is loaded lazily: asking for Brazil's states reads Brazil's file only, and `children` on a subdivision loads that branch on first access.

## Formatting addresses

Both formatters render according to the country's address format, in HTML (the default) or plain text (`html: false`).

### DefaultFormatter

Formats an address for display, always adding the localized country name.

```rb
address = Addressing::Address.new
  .with_country_code("US")
  .with_administrative_area("CA")
  .with_locality("Mountain View")
  .with_address_line1("1098 Alta Ave")

puts Addressing::DefaultFormatter.new.format(address)
# <p translate="no">
# <span class="address-line1">1098 Alta Ave</span><br>
# <span class="locality">Mountain View</span>, <span class="administrative-area">CA</span><br>
# <span class="country">United States</span>
# </p>
```

### PostalLabelFormatter

Renders a mailing label as plain text, uppercasing the fields the country requires for automated mail sorting.

It needs the origin country, so it can tell domestic mail from international. For domestic mail the country name is omitted entirely. For international mail the postal code gets the destination's prefix, and the country name is added in both the current locale and English — the Universal Postal Union's recommendation, to avoid trouble in countries of transit.

```rb
address = Addressing::Address.new
  .with_country_code("US")
  .with_administrative_area("CA")
  .with_locality("Mountain View")
  .with_postal_code("94043")
  .with_address_line1("1098 Alta Ave")

puts Addressing::PostalLabelFormatter.new.format(address, origin_country: "FR", locale: "fr-FR")
# 1098 Alta Ave
# MOUNTAIN VIEW, CA 94043
# ÉTATS-UNIS - UNITED STATES
```

## Validating addresses

For Active Record models:

```rb
class User < ApplicationRecord
  validates_address_format
end
```

This checks that every field the country requires is present, that no unused field is filled in, that the subdivisions exist, and that the postal code matches the country's pattern.

By default it validates all address fields, and only runs when at least one of them has changed. Pass `fields:` to narrow it down:

```rb
class User < ApplicationRecord
  validates_address_format fields: [:country_code, :administrative_area, :locality, :postal_code, :address_line1]
end
```

> **Note:** `fields:` controls which attributes are *read from your model*, not which ones the country requires. The US format requires a given name and family name, so a model without those columns will fail validation with "should not be blank". Use `field_overrides:` to tell the validator that your application does not collect them.

```rb
class User < ApplicationRecord
  validates_address_format(
    fields: [:country_code, :administrative_area, :locality, :postal_code, :address_line1],
    field_overrides: Addressing::FieldOverrides.new(
      Addressing::AddressField::GIVEN_NAME => Addressing::FieldOverride::HIDDEN,
      Addressing::AddressField::FAMILY_NAME => Addressing::FieldOverride::HIDDEN,
      Addressing::AddressField::ORGANIZATION => Addressing::FieldOverride::HIDDEN
    )
  )
end
```

```rb
User.new(country_code: "US", administrative_area: "CA", locality: "Mountain View",
         postal_code: "94043", address_line1: "1098 Alta Ave").valid?
# => true

user = User.new(country_code: "US", administrative_area: "XX", locality: "Mountain View",
                postal_code: "9404", address_line1: "1098 Alta Ave")
user.valid?
# => false
user.errors.full_messages
# => ["Administrative area should be valid", "Postal code should be valid"]
```

Each field can be overridden as `HIDDEN`, `OPTIONAL`, or `REQUIRED`. Skip postal code checking with `verify_postal_code: false`, and replace the default change-detection with any Active Record validation option:

```rb
validates_address_format if: -> { shipping_address_changed? }
```

## Contributing

Everyone is encouraged to help improve this project:

- [Report bugs](https://github.com/robinvdvleuten/addressing/issues)
- Fix bugs and [submit pull requests](https://github.com/robinvdvleuten/addressing/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started:

```
git clone https://github.com/robinvdvleuten/addressing.git
cd addressing
bundle install
bundle exec rake test
```

`rake test` regenerates `data/address_formats.dump` from `data/address_formats.json` first — the dump is a build artifact and is not committed.

Refreshing the country and address data from upstream (`rake addressing:generate`) additionally requires PHP, since it reads the definitions out of the commerceguys library.

Feel free to open an issue to get feedback on your idea before spending too much time on it.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for what has changed recently.

## Acknowledgements

This gem wouldn't exist without the PHP [addressing](https://github.com/commerceguys/addressing) library. The [CommerceGuys](https://github.com/commerceguys) did an excellent job figuring out how to parse Google's address data, as described in their [backstory](https://drupalcommerce.org/blog/16864/commerce-2x-stories-addressing). They built a PHP library where I needed a Ruby gem, so this project was born.

## License

The MIT License (MIT). See [LICENSE](LICENSE) for more information.

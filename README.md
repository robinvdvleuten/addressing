# Addressing

A Ruby addressing library, powered by CLDR and Google's address data.

- Countries, with translations for over 250 locales. Powered by [CLDR](http://cldr.unicode.org) v46.
- Address formats for over 200 countries.
- Subdivisions (administrative areas, localities, dependent localities) for 60 countries.
- Both latin and local subdivision names, when relevant (e.g: Okinawa / 沖縄県).
- Formatting, both in HTML and plain text.

Address formats and subdivisions were initially generated from [Google's Address Data Service](https://chromium-i18n.appspot.com/ssl-address), and are now owned and maintained by the library itself.

[![Build Status](https://img.shields.io/github/actions/workflow/status/robinvdvleuten/addressing/test.yml?branch=main)](https://github.com/robinvdvleuten/addressing/actions?query=workflow%3Atest)
[![MIT license](https://img.shields.io/github/license/robinvdvleuten/addressing.svg)](https://github.com/robinvdvleuten/addressing/blob/main/LICENSE)

## Installation

Add this line to your application’s Gemfile:

```rb
gem "addressing"
```

## Getting Started

The [Address](lib/addressing/address.rb) class represents a postal adddress, with attributes for the following fields:

- Country code
- Administrative area
- Locality (City)
- Dependent Locality
- Postal code
- Sorting code
- Address line 1
- Address line 2
- Address line 3
- Organization
- Given name (First name)
- Additional name (Middle name / Patronymic)
- Family name (Last name)

Field names follow the OASIS [eXtensible Address Language (xAL)](http://www.oasis-open.org/committees/ciq/download.shtml) standard.

```rb
# Create a new Address instance.
address = Addressing::Address.new(
  country_code: "US",
  administrative_area: "CA",
  locality: "Mountain View",
  dependent_locality: "MV",
  postal_code: "94043",
  sorting_code: "94044",
  address_line1: "1600 Amphitheatre Parkway",
  address_line2: "Google Bldg 41",
  organization: "Google Inc.",
  given_name: "John",
  additional_name: "L.",
  family_name: "Smith",
  locale: "en"
)

# Modify an existing instance through chainable methods.
address = address.with_country_code('US')
                 .with_administrative_area('CA')
```

The [AddressFormat](lib/addressing/address_format.rb) class provides the following information:

- Which fields are used, and in which order
- Which fields are required
- Which fields need to be uppercased for the actual mailing (to facilitate automated sorting of mail)
- The labels for the administrative area (state, province, parish, etc.), locality (city/post town/district, etc.), dependent locality (neighborhood, suburb, district, etc) and the postal code (postal code or ZIP code)
- The regular expression pattern for validating postal codes

```rb
# Get the address format for Brazil.
address_format = Addressing::AddressFormat.get('BR')
```

The [Country](lib/addressing/country.rb) class provides the following information:

- The country name.
- The numeric and three-letter country codes.
- The official currency code, when known.
- The timezones which the country spans.

```rb
# Get the country instance for Brazil.
brazil = Addressing::Country.get('BR')
p brazil.three_letter_code # BRA
p brazil.name # Brazil
p brazil.currency_code # BRL
p brazil.timezones

# Get all country instances.
countries = Addressing::Country.all

# Get the country list ({ country_code => name }), in French.
country_list = Addressing::Country.list('fr-FR')
```

The [Subdivision](lib/addressing/subdivision.rb) class provides the following information:

- The subdivision code (used to represent the subdivison on a parcel/envelope, e.g. CA for California)
- The subdivison name (shown to the user in a dropdown)
- The local code and name, if the country uses a non-latin script (e.g. Cyrilic in Russia).
- The postal code pattern (if different from the one on the address format).

Subdivisions are hierarchical and can have up to three levels: Administrative Area -> Locality -> Dependent Locality.

```rb
# Get the subdivisions for Brazil.
states = Addressing::Subdivision.all(['BR'])
states.each do |state|
  municipalities = state.children
end

# Get the subdivisions for Brazilian state Ceará.
municipalities = Addressing::Subdivision.all(['BR', 'CE'])
municipalities.each do |municipality|
  p municipality.name
end
```

### Formatting addresses

Addresses are formatted according to the address format, in HTML or text.

#### DefaultFormatter

Formats an address for display, always adds the localized country name.

```rb
address = Addressing::Address.new
address = address.with_country_code('US')
                 .with_administrative_area('CA')
                 .with_locality('Mountain View')
                 .with_address_line1('1098 Alta Ave')

formatter = Addressing::DefaultFormatter.new
p formatter.format(address)

# Output:
# <p translate="no">
# <span class="address-line1">1098 Alta Ave</span><br>
# <span class="locality">Mountain View</span>, <span class="administrative-area">CA</span><br>
# <span class="country">United States</span>
# </p>
```

#### PostalLabelFormatter

Takes care of uppercasing fields where required by the format (to facilitate automated mail sorting).

Requires specifying the origin country code, allowing it to differentiate between domestic and international mail. In case of domestic mail, the country name is not displayed at all. In case of international mail:

1. The postal code is prefixed with the destination's postal code prefix.
2. The country name is added to the formatted address, in both the current locale and English. This matches the recommendation given by the Universal Postal Union, to avoid difficulties in countries of transit.

```rb
address = Addressing::Address.new
address = address.with_country_code('US')
                 .with_administrative_area('CA')
                 .with_locality('Mountain View')
                 .with_address_line1('1098 Alta Ave')

formatter = Addressing::PostalLabelFormatter.new
p formatter.format(address, origin_country: "FR")

# Output:
# 1098 Alta Ave
# MOUNTAIN VIEW, CA 94043
# ÉTATS-UNIS - UNITED STATES
```

Upcasing can be disabled with `formatter.format(address, upcase: false)`

### Validating addresses

For Active Record models, use:

```rb
class User < ApplicationRecord
  validates_address_format
end
```

For performance, the address is only verified if at least one of the fields changes. Set your own condition with:

```rb
class User < ApplicationRecord
  validates_address if: -> { something_changed? }, ...
end
```

## Changelog

Please see [CHANGELOG](CHANGELOG.md) for more information on what has changed recently.

## Acknowledgements

This gem wouldn't exist when there wasn't the awesome PHP [addressing](https://github.com/commerceguys/addressing) library. The [CommerceGuys](https://github.com/commerceguys) did an excellent job figuring out how to parse Google's address data, as described by their [backstory](https://drupalcommerce.org/blog/16864/commerce-2x-stories-addressing). Unfortunately for me, they created a PHP library where I needed a Ruby gem so this project was born.

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/robinvdvleuten/addressing/issues)
- Fix bugs and [submit pull requests](https://github.com/robinvdvleuten/addressing/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```
git clone https://github.com/robinvdvleuten/addressing.git
cd addressing
bundle install
bundle exec rake test
```

Feel free to open an issue to get feedback on your idea before spending too much time on it.

## License

The MIT License (MIT). Please see [License File](LICENSE.md) for more information.

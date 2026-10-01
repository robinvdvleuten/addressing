# Changelog

All notable changes to `addressing` will be documented in this file.

## [2.2.0](https://github.com/robinvdvleuten/addressing/compare/v2.1.0...v2.2.0) (2026-10-01)


### Features

* add AddressValidator, which validates a plain address ([2d1b8fe](https://github.com/robinvdvleuten/addressing/commit/2d1b8fe8e7b501d8950a61349fa400bd1687d353)), closes [#52](https://github.com/robinvdvleuten/addressing/issues/52)
* add FieldViolation, one field of an address that breaks a rule of its address format ([2d1b8fe](https://github.com/robinvdvleuten/addressing/commit/2d1b8fe8e7b501d8950a61349fa400bd1687d353))
* remove the undocumented AddressFormatHelper class, whose required fields rule moved into AddressValidator ([2d1b8fe](https://github.com/robinvdvleuten/addressing/commit/2d1b8fe8e7b501d8950a61349fa400bd1687d353))
* remove the undocumented verify_address_format, verify_subdivisions and verify_postal_code methods from models that call validates_address_format ([2d1b8fe](https://github.com/robinvdvleuten/addressing/commit/2d1b8fe8e7b501d8950a61349fa400bd1687d353))
* support validates_address_format on plain ActiveModel classes ([821469b](https://github.com/robinvdvleuten/addressing/commit/821469b20779854f8af78e84dcdf4ef1985c7580)), closes [#57](https://github.com/robinvdvleuten/addressing/issues/57)


### Bug Fixes

* check origin_country with the other formatter options ([4e4dfbf](https://github.com/robinvdvleuten/addressing/commit/4e4dfbfe553bb106137b9e8b5076e7c1e5b8407a)), closes [#53](https://github.com/robinvdvleuten/addressing/issues/53)
* include address_line3 in validates_address_format default fields ([1739846](https://github.com/robinvdvleuten/addressing/commit/1739846ed3f5e3b03f3821fbb229f8a827078ed9)), closes [#47](https://github.com/robinvdvleuten/addressing/issues/47)
* load address formats from JSON and freeze their field lists ([e9bbbc1](https://github.com/robinvdvleuten/addressing/commit/e9bbbc1c8f5dd2c603fdc61676f27c9c238f7912)), closes [#43](https://github.com/robinvdvleuten/addressing/issues/43) [#49](https://github.com/robinvdvleuten/addressing/issues/49)
* make subdivision lookups independent of load order and platform ([31e1c4b](https://github.com/robinvdvleuten/addressing/commit/31e1c4b839419382d9cf95a66f51547906e65d89)), closes [#56](https://github.com/robinvdvleuten/addressing/issues/56)
* raise ArgumentError for a nil origin_country in PostalLabelFormatter ([954ba68](https://github.com/robinvdvleuten/addressing/commit/954ba68ce63224b5095e408160d762102b44752f)), closes [#45](https://github.com/robinvdvleuten/addressing/issues/45)
* read a subdivision definition that upstream writes as an empty array ([7dc6e72](https://github.com/robinvdvleuten/addressing/commit/7dc6e72fa76efe16e063f264a095bbdf83aafe1a))
* read the data files as UTF-8, independent of the locale ([aeafad8](https://github.com/robinvdvleuten/addressing/commit/aeafad861c637dd1e4b7e3b9e2f2931f129fa64c)), closes [#44](https://github.com/robinvdvleuten/addressing/issues/44)
* report a missing country code as a field violation ([15c23e6](https://github.com/robinvdvleuten/addressing/commit/15c23e63dc85a2cd394a2605fc57fd55ca8d0fb1)), closes [#58](https://github.com/robinvdvleuten/addressing/issues/58)
* share one blank check between Subdivision and AddressValidator ([b469c0b](https://github.com/robinvdvleuten/addressing/commit/b469c0b244bb771d624bebe9667e41090b46fba6))
* upcase country codes on Address and the postal label origin ([f1e6554](https://github.com/robinvdvleuten/addressing/commit/f1e6554d9291011f6e44bc91799646b9b7b39f62)), closes [#46](https://github.com/robinvdvleuten/addressing/issues/46)
* validate the html_tag and locale formatter options ([cbd90c3](https://github.com/robinvdvleuten/addressing/commit/cbd90c31daa569cd6418185bf4cfa36acc4d1078))


### Performance Improvements

* cache fewer country lists and address formats ([1c5bc0a](https://github.com/robinvdvleuten/addressing/commit/1c5bc0a142ad70c8a54a11c97c9b9a0562a66ab8))
* check for subdivision children without building them ([04eb8c1](https://github.com/robinvdvleuten/addressing/commit/04eb8c135bfb66b088ca9bd26b174a0540574c0f))

## [2.1.0](https://github.com/robinvdvleuten/addressing/compare/v2.0.1...v2.1.0) (2026-09-18)


### Features

* sync data with commerceguys repository (v2.3.0) ([0ccf627](https://github.com/robinvdvleuten/addressing/commit/0ccf627b2abed8498d0b81bf57075346aa75c401))
* sync data with commerceguys repository (v2.3.1) ([acf6e04](https://github.com/robinvdvleuten/addressing/commit/acf6e042a3eb08f932f17db339689ab76baffacd))

## [2.0.1](https://github.com/robinvdvleuten/addressing/compare/v1.1.0...v2.0.1) (2026-05-27)


### ⚠ BREAKING CHANGES

* drop support for ruby 3.2 and test on 4.0
* drop support for ruby 3.1 and test on 3.4

### Features

* sync data with commerceguys repository (v2.2.3) ([b0f27f1](https://github.com/robinvdvleuten/addressing/commit/b0f27f177fdfb2b8920fd76989d32e42be3f8efe))
* sync data with commerceguys repository (v2.2.5) ([2d0ae16](https://github.com/robinvdvleuten/addressing/commit/2d0ae16982a04ddbd42c5a70ed0c61f9727493af))


### Miscellaneous Chores

* drop support for ruby 3.1 and test on 3.4 ([6f54870](https://github.com/robinvdvleuten/addressing/commit/6f54870c554f0e295bffc386005c86dda4c5a8a0))
* drop support for ruby 3.2 and test on 4.0 ([c840b10](https://github.com/robinvdvleuten/addressing/commit/c840b10b84c5c95df977f3ba3d8a84ae201f34ef))

## 1.1.0 (2025-10-03)

- Add formatter-level caching for Country.list
- Refactor FieldOverrides initialization to be more idiomatic
- Add equality methods to Address class
- Refactor complex values method in DefaultFormatter
- Extract magic strings to constants
- Simplify boolean validation in formatter options
- use .new() for UnknownLocaleError
- Added RDoc documentation
- Replaced class variables with class instance variables
- Add custom exception classes for better error handling
- Refactor Address class
- Fix test bug in address_test.rb
- Remove duplicate code in Model validation
- add missing % to generic address format

## 1.0.0 (2024-10-21)

- Sync data with commerceguys repository (v2.2.2)
- Drop support for Ruby 3.0

## 0.7.0 (2024-01-30)

- Update subdivisions for Philippines (PH)
- Add missing Indonesian (ID) provinces: PD, PE, PS, PT
- Update subdivisions for India (IN)
- Allow turning off postal code validation
- Singapore lacks city/locality field
- Allow address formats to declare default values
- Sync data with commerceguys repository (v2.1.1)

## 0.6.0 (2023-11-22)

- Sync data with commerceguys repository (v2.1.0)
- Update to CLDR v44
- Switch to keying subdivisons by ISO code, where available
- Add support for a third address line
- Extract country + subdivision data from commerceguys repository
- Stop generating formats and subdivisions from Google's dataset
- Drop support for Ruby 2.7
- Remove obsolete postal_code_pattern_type from subdivisions

## 0.5.0 (2023-02-16)

- Update CLDR to v42

## 0.4.0 (2022-07-13)

- Update CLDR to v41

## 0.3.1 (2022-04-04)

- Break with both subdivisions and parents when subdivision field is empty
- Only retrieve field if it exists on model

## 0.3.0 (2022-04-04)

- Allow field validation to be overridden
- Only verify address when one of the field changes
- Allow used address fields to be configured

## 0.2.0 (2022-02-25)

- Add ActiveRecord validations

## 0.1.1 (2022-02-21)

- Fix typo in DE custom format

## 0.1.0 (2022-02-07)

- Initial release

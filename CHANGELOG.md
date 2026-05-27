# Changelog

All notable changes to `addressing` will be documented in this file.

## [2.0.0](https://github.com/robinvdvleuten/addressing/compare/v1.1.0...v2.0.0) (2026-05-27)


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

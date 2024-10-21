# Changelog

All notable changes to `addressing` will be documented in this file.

## UNRELEASED

- Sync data with commerceguys repository (v2.2.2)

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

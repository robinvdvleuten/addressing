# Changelog

All notable changes to `addressing` will be documented in this file.

## UNRELEASED

- Singapore lacks city/locality field
- Allow address formats to declare default values
- Sync data with commerceguys repository (v2.1.1)

## 0.6.0 (22-11-2023)

- Sync data with commerceguys repository (v2.1.0)
- Update to CLDR v44
- Switch to keying subdivisons by ISO code, where available
- Add support for a third address line
- Extract country + subdivision data from commerceguys repository
- Stop generating formats and subdivisions from Google's dataset
- Drop support for Ruby 2.7
- Remove obsolete postal_code_pattern_type from subdivisions

## 0.5.0 (16-02-2023)

- Update CLDR to v42

## 0.4.0 (13-07-2022)

- Update CLDR to v41

## 0.3.1 (04-04-2022)

- Break with both subdivisions and parents when subdivision field is empty
- Only retrieve field if it exists on model

## 0.3.0 (04-04-2022)

- Allow field validation to be overridden
- Only verify address when one of the field changes
- Allow used address fields to be configured

## 0.2.0 (25-02-2022)

- Add ActiveRecord validations

## 0.1.1 (21-02-2022)

- Fix typo in DE custom format

## 0.1.0 (07-02-2022)

- Initial release

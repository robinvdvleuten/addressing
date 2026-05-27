# Changelog

All notable changes to `addressing` will be documented in this file.

## [2.0.0](https://github.com/robinvdvleuten/addressing/compare/addressing-v1.1.0...addressing/v2.0.0) (2026-05-27)


### ⚠ BREAKING CHANGES

* drop support for ruby 3.2 and test on 4.0
* drop support for ruby 3.1 and test on 3.4

### Features

* Add missing ISO codes for two TW subdivisions ([0b20843](https://github.com/robinvdvleuten/addressing/commit/0b20843539349484ce25dd0fc89bda2585ae572f))
* Add support for a third address line ([a7724c7](https://github.com/robinvdvleuten/addressing/commit/a7724c74834b6fa94bcef61b8590521865033ad1))
* Add third address line to generic format definition ([602478f](https://github.com/robinvdvleuten/addressing/commit/602478f4d5409dfac447e0c1cce3808748476d87))
* Allow address formats to declare default values ([bd152d8](https://github.com/robinvdvleuten/addressing/commit/bd152d8a3c4391367fe7017ae154b76c452ac505))
* Allow turning off postal code validation ([218b081](https://github.com/robinvdvleuten/addressing/commit/218b081cb3573252ab9de9d7910a8c83cd695dbb))
* Decrease the subdivision dataset size by removing redundant data ([e85219b](https://github.com/robinvdvleuten/addressing/commit/e85219ba97db1d4f6b5ceab2ab2fcde7442d3e56))
* Drop support for Ruby 2.7 ([b851ce3](https://github.com/robinvdvleuten/addressing/commit/b851ce361a2853def51ba72be308201d8b5f3eed))
* Extract country + subdivision data from commerceguys repository ([cfd60a6](https://github.com/robinvdvleuten/addressing/commit/cfd60a690eb135ff58fc9afc5a7b0184b8425cf1))
* Extract formats from commerceguys repository ([421bfa4](https://github.com/robinvdvleuten/addressing/commit/421bfa47c92b5ef35729810f39632e43191c6cf3))
* Fix spelling of AE-RK ([1729243](https://github.com/robinvdvleuten/addressing/commit/17292430168e44159c2a96cfd79269f2dd3f9375))
* Make code a required property of subdivision ([87bc768](https://github.com/robinvdvleuten/addressing/commit/87bc768dce30af0b9f741b239b05cbd4eb6ee150))
* Make the region field required in Turkey ([099900f](https://github.com/robinvdvleuten/addressing/commit/099900f42edb13bbdb8e9aceabe753203751741a))
* Remove Jervis Bay from Australian subdivisions ([110ac14](https://github.com/robinvdvleuten/addressing/commit/110ac14b74cf7c841741d84b922ddb1aef5ba699))
* Remove obsolete postal_code_pattern_type from subdivisions ([7df53f2](https://github.com/robinvdvleuten/addressing/commit/7df53f21483bf8587fb5d5ca9460c62c9e31cb55))
* Remove sorting codes from French territories ([c78c338](https://github.com/robinvdvleuten/addressing/commit/c78c338602c2d751afc57d45504587cf585b8b70))
* Rename PH-COM (sync with ISO) ([85fe2ac](https://github.com/robinvdvleuten/addressing/commit/85fe2aceb0e24bd63acd2c6bb82a4216fd6a8ad9))
* Rever changes to Cabo Verde subdivisions ([4c68d70](https://github.com/robinvdvleuten/addressing/commit/4c68d7035585dfa44b746b1fa68f5f0d0f8585dc))
* Stop generating formats and subdivisions from Google's dataset ([31dee7b](https://github.com/robinvdvleuten/addressing/commit/31dee7bb97b8c13ba9d057c9ec58564d09e5a2aa))
* Switch to keying subdivisons by ISO code, where available ([c62db99](https://github.com/robinvdvleuten/addressing/commit/c62db99069fef5b188edc355f92b502e2d055025))
* Sync data with commerceguys ([03385cc](https://github.com/robinvdvleuten/addressing/commit/03385cc0e49d3f2df85d28d5a2bf82712c97fdc4))
* Sync data with commerceguys ([21fcd98](https://github.com/robinvdvleuten/addressing/commit/21fcd98394f18badaf47e32b8e411da576988117))
* Sync data with commerceguys repository (v2.1.1) ([7b27f4d](https://github.com/robinvdvleuten/addressing/commit/7b27f4d7525c0fb5a7e4664d9a49cd5dfab2698a))
* Sync data with commerceguys repository (v2.2.0) ([a66bdac](https://github.com/robinvdvleuten/addressing/commit/a66bdac800c6f509b08e676512df1eb82fcf25e7))
* Sync data with commerceguys repository (v2.2.2) ([530fe6e](https://github.com/robinvdvleuten/addressing/commit/530fe6e654f2aebf146b28c7e10ddfdd77bf1860))
* sync data with commerceguys repository (v2.2.3) ([b0f27f1](https://github.com/robinvdvleuten/addressing/commit/b0f27f177fdfb2b8920fd76989d32e42be3f8efe))
* sync data with commerceguys repository (v2.2.5) ([2d0ae16](https://github.com/robinvdvleuten/addressing/commit/2d0ae16982a04ddbd42c5a70ed0c61f9727493af))
* The administrative_area_type for France should be `region` ([4b44e49](https://github.com/robinvdvleuten/addressing/commit/4b44e49e1a337784386e667ffe5988e4f4c18cb6))
* Update subdivisions for Philippines (PH) ([4115255](https://github.com/robinvdvleuten/addressing/commit/4115255965e8cb5ce9cfc95aab3c07f538f41065))
* Update to CLDR v43 ([65700f8](https://github.com/robinvdvleuten/addressing/commit/65700f8eb5c6cab682598f47c9d172a62e413092))
* When uppercasing address lines 1 and 2, uppercase line 3 as well ([09b2d28](https://github.com/robinvdvleuten/addressing/commit/09b2d281e7c6b45cc5af99f13afdf7a73151ee82))


### Bug Fixes

* Add missing Indonesian (ID) provinces: PD, PE, PS, PT ([13dfaef](https://github.com/robinvdvleuten/addressing/commit/13dfaefbb5ede22f9554f58f09f7a0bc84aa8e41))
* Singapore lacks city/locality field ([ddc92b4](https://github.com/robinvdvleuten/addressing/commit/ddc92b40a69237088e1e15d3d02b838a2917434d))
* Update subdivisions for India (IN) ([8937b37](https://github.com/robinvdvleuten/addressing/commit/8937b372482af61b44d3a3febf0032fbbf6bb816))


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

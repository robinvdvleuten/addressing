# Addressing

Describes how each country writes a postal address, so that an address can be formatted and validated correctly for its country.

## Language

### Subdivisions

**Subdivision level**:
One of the three tiers into which a country divides its territory for addressing: administrative area, locality, dependent locality. The levels are ordered from the largest area down.
_Avoid_: Depth, tier, subdivision field

**Predefined subdivision**:
A subdivision that exists in the dataset for a country, as opposed to free text that an address holds at a subdivision level.
_Avoid_: Known subdivision, valid subdivision

**Subdivision chain**:
The predefined subdivisions that match one address, ordered from the administrative area downward. Each entry is the parent of the next.
_Avoid_: Hierarchy, parents, path

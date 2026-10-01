# Addressing

Describes how each country writes a postal address, so that an address can be formatted and validated correctly for its country.

## Language

**Address format**:
How one country writes a postal address: which fields it uses, in which order and on which lines, which fields are required, and which are written in uppercase.
_Avoid_: Layout, template

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

**Subdivision group**:
The predefined subdivisions of one country that share the same parents. Each subdivision group has its own key, derived from those parents.
_Avoid_: Level, sibling set, subdivision list

### Validation

**Field violation**:
One field of an address that breaks a rule of the address format for its country, together with the kind of rule it breaks. A blank country code is also a field violation, because without a country there is no address format. Validating an address gives a list of field violations; an empty list means the address is valid.
_Avoid_: Error, validation error

### Formatting

**Postal label**:
An address written for a mail carrier rather than for display. Fields are uppercased where the address format requires it. Domestic mail leaves out the country; international mail adds the postal code prefix and names the country in the language the label is written in, and in English.
_Avoid_: Shipping label, mailing address

**Origin country**:
The country that a postal label is sent from. It decides whether the mail is domestic or international.
_Avoid_: Sender country, from country

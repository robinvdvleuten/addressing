# The data sync copies upstream unchanged and writes only to data/

The data sync copies upstream's subdivision files byte for byte. It changes only their names, to our subdivision group key: SHA1, because Ruby has no Tiger hash, which upstream uses. Data that upstream keeps in PHP source is extracted with PHP and written as JSON under `data/`, never as Ruby literals in `lib/`. PHP quirks in the data, such as `[]` for an empty object, are handled where the runtime reads the data. The available locales are derived from the files in `data/country/` and are not stored separately.

We chose this because generating Ruby source tied the sync to the indentation of `country.rb` and `locale.rb`, and needed a set of literal printers that existed only for that purpose. Rewriting upstream's files in the sync made it impossible to diff our data against upstream.

## Consequences

- `diff -r` between upstream's `resources/subdivision` and `data/subdivision` shows only renamed files.
- The subdivision group key is defined once, in `Subdivision`, and the sync calls it.
- A sync changes only files under `data/`, never under `lib/`.
- `data/UPSTREAM_VERSION` records which upstream tag the shipped data comes from.

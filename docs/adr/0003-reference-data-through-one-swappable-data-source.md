# Reference data is read through one swappable data source, and malformed data fails loudly

`Country`, `Locale`, `Subdivision` and `AddressFormat` read their datasets through one data source. The data source knows where the data lives, reads it as UTF-8, parses the JSON and caches what each reader makes of it. Each reader keeps its own processing and its own policy for an unknown key: raise, `nil`, or the generic address format. The process uses one data source at a time. Tests replace it with a data source on a fixture directory, and a new data source starts with an empty cache, so there is no reset.

A missing dataset gives `nil`. Malformed JSON raises, for every dataset. Before this change, `Subdivision` treated a malformed file as if the file did not exist, and so does upstream. We diverge here on purpose. The data files are never edited by hand (ADR 0001), so malformed data means that a sync broke. A silent empty result would hide that, and the subdivisions of a country would disappear without an error. Valid JSON of the wrong shape, such as a subdivision file without a `subdivisions` object, still gives no subdivisions at runtime. The data verifier reports it, and it runs in CI, so a sync that produces it fails there instead of in an application.

We rejected two alternatives. Keeping a loader in each class kept the cost of five copies of path, encoding, parse and cache code, and gave tests no seam besides FakeFS and private instance variables. A data source that also processes the data would have to know about subdivisions and address formats, and a fixture data source could then no longer be a plain directory.

## Consequences

- Tests select data by directory. They do not stub the file system or reset private state.
- Behavioral tests run against fixtures. Separate test suites guard the shipped data against a bad sync.
- The data source is `@api private`. A public option to bring your own data directory is a separate decision.
- The data sync still writes files directly (ADR 0002). Only the runtime and the data verifier read through the data source.

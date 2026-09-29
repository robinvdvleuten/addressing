# Diverge from upstream where it mishandles input

This gem is a port of the PHP library commerceguys/addressing, and its data is synced from there. The structure and behavior of the port follow upstream by default, so that a data sync or a comparison against the PHP source stays simple. We diverge on purpose in two cases: where upstream gives a wrong or platform-dependent result for an input, and where a rule is implemented more than once upstream and the copies can drift.

The alternative was to stay identical and document the limitations. We rejected it because the wrong results are silent: a lowercase country code formats with the correct layout but the wrong country line, and a subdivision lookup returns a different answer depending on which data was loaded first.

## Consequences

- A divergence changes behavior only for input that upstream handles incorrectly. For correct input, the port and upstream give the same result.
- The data files are never edited by hand. A defect in the data is reported upstream and arrives with the next sync.
- Each divergence is recorded in the issue that introduced it, with the upstream behavior it replaces.

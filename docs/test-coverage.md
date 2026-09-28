# Test and CI coverage

`tests/all.sh` is the authoritative local and CI entry point. The GitHub Actions
workflow runs it with the runner's current Bash, a source-built checksum-pinned
GNU Bash 3.2.57, and macOS `/bin/bash` after asserting that the latter is 3.2.

| Contract | Coverage |
|---|---|
| Bash 3.2 syntax | Every library, executable, schema, generator, installer, and test is checked with the active matrix interpreter |
| Forbidden Bash 4+ features | `tests/forbidden-features.sh` scans runtime Bash sources for associative arrays, namerefs, `mapfile`, case conversion, `[[ -v ]]`, `eval`, and related syntax |
| Parser forms and failures | `tests/extended.sh` covers long, equals, short, boolean, tri-state, aliases, arrays, positionals, unknown policies, missing values, duplicates, required fields, types, validators, and constraints |
| Exact argv integrity | `tests/run.sh`, `tests/extended.sh`, and `tests/integration-preview.sh` compare arrays element by element, including empty, whitespace, metacharacter, Unicode, newline, and post-`--` values |
| Defaults and provenance | Literal, inherited, environment, callback, alias, positional, and explicit sources are asserted |
| Generated interfaces | Determinism, JSON parsing, completion syntax/content, terminal help, Markdown, GUI metadata, static interactive showcases, and HTML conversion are tested |
| Side-effect-free introspection | Fixture markers prove that schema export exits before application logic and dynamic defaults run only during parsing |
| Error behavior and shell modes | Status 2, option-specific diagnostics, nounset cleanliness, and representative `set -e` handling are asserted |
| Filesystem and concurrency safety | Parallel parser processes run without shared parser files; static audit rejects `eval` and generated parser code |
| Installation and completion | The demo is staged under a temporary prefix and its installed command and completion are exercised |
| GUI adapter | The shared model is tested element by element for empty, multiline, metacharacter, Unicode, store-constant, positional, and remainder values; validation, Basic/Advanced classification, conditional labels, file modes, static HTML, and the demo hook are checked |
| WISE/ContainerXP migration surface | Nine command twins test shared options, aliases, compound actions, passthrough, required input, legacy defaults, completion, JSON, and GUI forms |
| Documentation synchronization | Generated snapshots, all public functions/attributes, and every repository-local Markdown link are checked |

## Residual platform coverage

Linux execution under GNU Bash 3.2 proves language compatibility but does not
model every macOS utility difference. The macOS runner covers the complete
behavioral suite with system Bash. Browser opening, WISE port-forward UI,
Docker availability, native file chooser interaction, and package-manager
installation are environment integrations and are documented but not automated
in this library CI. The frontend modules are covered through their shared model;
interactive Tk/Qt window tests remain platform packaging checks.

The integration previews are pinned to a documented local source snapshot.
CI cannot detect future WISE or ContainerXP CLI drift because those repositories
are intentionally not fetched or modified. Updating the snapshot requires a
new manual comparison and corresponding schema/test changes.

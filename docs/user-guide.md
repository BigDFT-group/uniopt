# Using UniOpt in a Bash program

UniOpt lets a Bash program describe its command line once and reuse that schema
for parsing, validation, help, documentation, completion, and machine-readable
metadata. It requires Bash 3.2 or later and preserves the original argument
boundaries throughout parsing.

## Why use it

A hand-written `case` parser usually duplicates the same facts in several
places: parsing code, default initialization, validation, `--help`, README
tables, and completion. Those copies drift. UniOpt keeps the option ID, CLI
spellings, type, default, help, and constraints in one declaration.

The practical benefits are:

- values containing spaces, empty strings, wildcard characters, quotes,
  backslashes, Unicode, and newlines remain separate arguments;
- validation and relationships between options are applied consistently;
- every value has provenance, so the application can distinguish a default,
  inherited setting, environment setting, callback result, or CLI override;
- terminal help, Markdown, JSON, and completion come from the same schema;
- stable semantic IDs let a GUI or another integration survive spelling changes;
- the parser uses no `eval`, generated parser scripts, or temporary files.

## Start with the demo

From the repository root:

```bash
./examples/uniopt-demo/uniopt-demo --help
./examples/uniopt-demo/uniopt-demo --style formal --tag docs --tag public Ada
./examples/uniopt-demo/uniopt-demo --quick --show-sources Ada -- '' 'two words' '*'
```

Read the [demo schema](https://github.com/bigdft-group/uniopt/blob/main/examples/uniopt-demo/schema.sh) beside the
[demo program](https://github.com/bigdft-group/uniopt/blob/main/examples/uniopt-demo/uniopt-demo). The schema has no
application side effects, so `bin/uniopt` can safely inspect it.

For larger, real-world interfaces, the
[WISE and ContainerXP integration previews](https://github.com/bigdft-group/uniopt/tree/main/examples/integration-preview)
provide nine side-effect-free command twins. They show the schema and packaging
work required to add completion and GUI forms before either application is
migrated. The documentation site presents each schema as an
[interactive GUI advisor](generated/integration-preview/wise-env.md), so users
can explore the controls and generated command lines without installing or
running the reference applications.

## Structure your program

Keep registration in a function, preferably in a separate schema file:

```bash
mytool_schema() {
  uniopt_reset
  uniopt_schema mytool --summary "Process an input file" --unknown error

  uniopt_option output.format \
    --short -f --long --format --dest FORMAT --type enum \
    --choice text --choice json --default text \
    --metavar FORMAT --help "Output format"

  uniopt_option input.include \
    --short -I --long --include --dest INCLUDES --type path --repeatable \
    --metavar PATH --help "Additional input path"

  uniopt_positional input.file \
    --dest INPUT --type path --required --metavar INPUT \
    --help "Input file"
}
```

Then load, register, and parse:

```bash
#!/usr/bin/env bash
set -u

source /path/to/uniopt.sh
source /path/to/mytool-schema.sh
mytool_schema

uniopt_parse "$@" || exit 2
if [[ "$UNIOPT_ACTION" == help ]]; then uniopt_help; exit 0; fi
if [[ "$UNIOPT_ACTION" == gui ]]; then
  exec uniopt gui /path/to/mytool-schema.sh mytool_schema -- "$0"
fi

uniopt_get_all input.include
INCLUDES=("${UNIOPT_RESULT[@]}")

printf 'format=%s input=%s\n' "$FORMAT" "$INPUT"
for path in "${INCLUDES[@]}"; do
  printf 'include=%s\n' "$path"
done
```

Scalar values are also available by semantic ID with `uniopt_get`. Repeatable,
remainder, and collected unknown values use `UNIOPT_RESULT`; copy it before the
next multi-value getter.

## Help and application control options

`uniopt_schema` automatically registers reserved `-h`/`--help` and `--gui`
options. `uniopt_parse` recognizes them before required-input validation and
sets `UNIOPT_ACTION` to `help` or `gui`. Handle that action immediately after
parsing, before application side effects. The GUI command opens a Basic and an
Advanced area, marks constrained fields as conditional, validates with the
same parser, and then runs the fixed executable with the constructed argv.

For tools that expose several introspection modes, keep the schema in a
side-effect-free file and use the companion command:

```bash
uniopt help mytool-schema.sh mytool_schema
uniopt markdown mytool-schema.sh mytool_schema
uniopt json mytool-schema.sh mytool_schema
uniopt completion mytool-schema.sh mytool_schema
```

## Defaults and provenance

Choose one default source for a scalar option:

```bash
uniopt_option output.format --long --format --dest FORMAT --default text
uniopt_option auth.token --long --token --dest TOKEN --default-env MYTOOL_TOKEN
uniopt_option runtime.dir --long --runtime-dir --dest RUNTIME_DIR \
  --default-fn mytool_default_runtime_dir
```

A default callback receives the name of an output variable:

```bash
mytool_default_runtime_dir() {
  printf -v "$1" '%s' "${TMPDIR:-/tmp}/mytool"
}
```

Callbacks and environment reads happen during `uniopt_parse`, never during
help, Markdown, JSON, or completion generation. Query the selected source with:

```bash
printf 'format came from %s\n' "$(uniopt_get_source output.format)"
```

## Booleans, tri-state values, and aliases

A boolean with a negative spelling records explicit enable/disable choices:

```bash
uniopt_option output.color --long --color --neg-long --no-color \
  --dest COLOR --type boolean --default true
```

Use `tristate` when omission means “inherit from another configuration layer”:

```bash
uniopt_option output.color --long --color --neg-long --no-color \
  --dest COLOR --type tristate --default inherit
```

Aliases are preset actions and can update several semantic options atomically:

```bash
uniopt_alias preset.quick --long --quick \
  --set output.format text --set output.loud true \
  --help "Select terse, loud output"
```

## Constraints

Declare constraints after all referenced IDs:

```bash
uniopt_constraint mutex mode.client mode.server
uniopt_constraint one-of action.create action.update action.delete
uniopt_constraint requires tls.cert tls.enabled
uniopt_constraint conflicts network.host network.publish
```

`mutex` permits zero or one explicit member. `one-of` requires exactly one.
Defaults do not count as explicit occurrences.

## Bash completion

Generate and source a completion definition:

```bash
bin/uniopt completion mytool-schema.sh mytool_schema >mytool.bash
source mytool.bash
```

UniOpt completes option spellings, enum values, and paths for path-typed
options. The generated code uses Bash's `complete`, `compgen`, and `COMPREPLY`
interfaces. It works without an additional package, although a completion
manager can load installed definitions automatically. The GNU Bash manual
documents the underlying [programmable completion model](https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion.html).

For a universally portable per-user setup, source the generated file from
`~/.bash_profile`. On macOS, Homebrew documents both the system-Bash-compatible
`bash-completion` package and its completion search paths in its
[shell completion guide](https://docs.brew.sh/Shell-Completion).

## Generate documentation and JSON

The same schema can produce a checked-in CLI reference and GUI input:

```bash
bin/uniopt markdown mytool-schema.sh mytool_schema >mytool-options.md
bin/uniopt json mytool-schema.sh mytool_schema >mytool.schema.json
```

Regenerate these files in the project build and fail CI when the committed
copies differ. UniOpt itself demonstrates this with `scripts/generate-docs` and
`scripts/check-docs`.

See the [complete API reference](api-reference.md) for every function,
attribute, type, status, and public result variable.

To distribute the finished command with generated completion, follow
[Distributing an installable UniOpt command](distributing-a-script.md).

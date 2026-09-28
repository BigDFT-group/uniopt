# UniOpt public API reference

This page is the complete public contract for `lib/uniopt.sh`. Functions whose
names begin with `uniopt__` and registry variables not named here are internal.
CI checks that every public `uniopt_*` function and every declaration attribute
appears in this page.

## General contract

- Minimum interpreter: Bash 3.2.
- Declaration and renderer functions return zero on success.
- Parser and validation errors return status 2, set `UNIOPT_ERROR`, and print a
  diagnostic prefixed with `uniopt:` to standard error.
- Semantic IDs match `[a-z][a-z0-9_.-]*` and are independent of CLI spellings.
- Destination and callback-output variable names must be ordinary Bash
  identifiers.
- Schema registration and rendering do not execute dynamic defaults,
  environment reads, validators, or application logic.

## Public variables

| Variable | Meaning |
|---|---|
| `UNIOPT_ERROR` | Most recent UniOpt diagnostic without the `uniopt:` prefix |
| `UNIOPT_ACTION` | Empty after an ordinary parse, `help` after `-h`/`--help`, or `gui` after `--gui` |
| `UNIOPT_RESULT` | Indexed result array replaced by `uniopt_get_all` or `uniopt_get_unknown` |
| `UNIOPT_INTROSPECT` | Set to `1` by `bin/uniopt` while sourcing a schema file |
| `UNIOPT_LIB` | Optional path overriding library discovery in `bin/uniopt` |

Application destinations declared with `--dest` are also assigned for scalar
options and scalar positionals. Repeatable, remainder, and unknown values must
be read through the result getters.

## Schema lifecycle

### `uniopt_reset`

Clears the active schema, parsed values, constraints, and result arrays. Call it
before registering a command. The library calls it once when sourced.

### `uniopt_schema COMMAND [ATTRIBUTES]`

Starts command metadata after a reset.

| Attribute | Argument | Meaning |
|---|---|---|
| `--summary` | `TEXT` | One-line command description |
| `--ui-confirm` | `TEXT` | Confirmation shown by a GUI immediately before execution |
| `--unknown` | `error`, `collect`, or `stop` | Unknown-argument policy; default `error` |
| `--unknown-dest` | `VARIABLE` | Compatibility metadata required by `collect` and `stop` |

`collect` keeps parsing later known options. `stop` places the first unknown
argument and the untouched tail in the unknown result.

### `uniopt_option ID ATTRIBUTES`

Declares an option or an internal scalar target.

| Attribute | Argument | Meaning |
|---|---|---|
| `--short` | `-x` | One-character short spelling |
| `--long` | `--name` | Long spelling |
| `--neg-long` | `--no-name` | Negative boolean or tri-state spelling |
| `--dest` | `VARIABLE` | Scalar destination; required for all options |
| `--type` | `TYPE` | Value type; default `string` |
| `--default` | `VALUE` | Literal scalar default |
| `--default-fn` | `FUNCTION` | Parser-time callback receiving an output-variable name |
| `--default-env` | `VARIABLE` | Parser-time shell/environment variable default |
| `--metavar` | `WORD` | Value label in help and documentation |
| `--help` | `TEXT` | User-facing description |
| `--repeatable` | none | Store every occurrence as a multi-value result |
| `--required` | none | Require an explicit occurrence |
| `--internal` | none | Hide a spelling-free target used by aliases |
| `--choice` | `VALUE` | Add an enum value; repeat for each choice |
| `--validator` | `FUNCTION` | Call `FUNCTION VALUE`; zero accepts the value |
| `--store-const` | `VALUE` | Consume no argument and store the constant |
| `--ui-label` | `TEXT` | Preferred GUI field label |
| `--ui-group` | `TEXT` | GUI section name |
| `--ui-control` | `CONTROL` | Advisory widget choice; default `auto` |
| `--ui-placeholder` | `TEXT` | Advisory empty-field prompt |
| `--ui-advanced` | none | Mark the field as advanced |
| `--ui-order` | `INTEGER` | Sort key within a generated GUI |
| `--ui-min` | `VALUE` | Advisory lower bound for a numeric widget |
| `--ui-max` | `VALUE` | Advisory upper bound for a numeric widget |
| `--ui-step` | `VALUE` | Advisory numeric-widget increment |
| `--ui-file-mode` | `auto`, `open`, `save`, or `directory` | Native chooser behavior for a path |

An option needs `--short` or `--long` unless it is `--internal`. Static,
environment, and callback defaults are mutually exclusive. Repeatable options
cannot have scalar defaults.

Supported types:

| Type | Validation and presentation |
|---|---|
| `string` | Any scalar string |
| `path` | Any scalar string; enables path completion |
| `int`, `integer` | Optional minus sign followed by digits |
| `uint` | Digits only |
| `enum` | Exact match with one of the `--choice` values |
| `boolean` | `true` or `false`; CLI spellings consume no value |
| `tristate` | `inherit`, `true`, or `false`; positive/negative spellings set explicit states |

### `uniopt_alias ID ATTRIBUTES`

Declares a no-argument preset action.

| Attribute | Argument | Meaning |
|---|---|---|
| `--short` | `-x` | Optional short spelling |
| `--long` | `--name` | Optional long spelling |
| `--help` | `TEXT` | User-facing description |
| `--set` | `OPTION_ID VALUE` | Assign a previously declared option; repeat as needed |
| `--ui-label` | `TEXT` | Preferred GUI action label |
| `--ui-group` | `TEXT` | GUI section name |
| `--ui-control` | `CONTROL` | Advisory widget choice |
| `--ui-placeholder` | `TEXT` | Advisory prompt if the renderer uses an input widget |
| `--ui-advanced` | none | Mark the action as advanced |
| `--ui-order` | `INTEGER` | Sort key within a generated GUI |

At least one spelling and one `--set` are required. Target values pass through
the target option's type and custom validation.

### `uniopt_positional ID ATTRIBUTES`

Declares one positional argument.

| Attribute | Argument | Meaning |
|---|---|---|
| `--dest` | `VARIABLE` | Scalar compatibility destination; required |
| `--type` | `TYPE` | Same type validation as options |
| `--metavar` | `WORD` | Usage and documentation label |
| `--help` | `TEXT` | User-facing description |
| `--required` | none | Require the positional |
| `--remainder` | none | Capture every remaining argument as a multi-value result |
| `--validator` | `FUNCTION` | Additional parser-time validator |
| `--ui-label` | `TEXT` | Preferred GUI field label |
| `--ui-group` | `TEXT` | GUI section name |
| `--ui-control` | `CONTROL` | Advisory widget choice |
| `--ui-placeholder` | `TEXT` | Advisory empty-field prompt |
| `--ui-advanced` | none | Mark the field as advanced |
| `--ui-order` | `INTEGER` | Sort key within a generated GUI |
| `--ui-file-mode` | `auto`, `open`, `save`, or `directory` | Native chooser behavior for a path |

Only one remainder positional should be declared. A literal `--` ends option
parsing and sends its untouched tail to that remainder.

### GUI presentation attributes

Presentation attributes are optional metadata. They appear under each item's
`ui` object in JSON and have no effect on parsing, validation, help, Markdown,
or completion. This separation lets a generic GUI improve its layout without
changing the command contract.

`CONTROL` is one of `auto`, `text`, `textarea`, `password`, `number`, `select`,
`radio`, `checkbox`, `tristate`, `file`, `directory`, `list`, or `hidden`.
Renderers may fall back to a control inferred from the core type when a hint is
not practical. For example, a web page cannot turn a browser file upload into
a local CLI path, while a native desktop renderer can use a file picker.

`--ui-min`, `--ui-max`, and `--ui-step` are available on options. Their values
are exported as strings so applications can choose an appropriate numeric
representation. They are interface hints and do not replace a UniOpt type or
custom validator. `--ui-order` must be an integer.
`--ui-file-mode` is accepted only for `path` options and positionals; `auto`
uses the control hint and otherwise opens an existing-file chooser.

### Built-in control options

Every call to `uniopt_schema` registers `interface.help` (`-h`, `--help`) and
`interface.gui` (`--gui`). These stable IDs are exported in JSON and completion
but hidden from generated GUI forms. Application declarations cannot reuse
these spellings. Either action bypasses required-value checks and makes
`uniopt_parse` return zero with `UNIOPT_ACTION` set. The application then
renders help or launches the advisor before executing domain logic.

### `uniopt_constraint KIND ID...`

Adds a relationship between already declared IDs.

| Kind | Cardinality | Rule |
|---|---:|---|
| `mutex` | two or more | At most one member may be explicit |
| `one-of` | two or more | Exactly one member must be explicit; `one_of` is accepted as an alias |
| `requires` | exactly two | The first explicit member requires the second |
| `conflicts` | exactly two | The two members cannot both be explicit |

## Parsing and validation

### `uniopt_parse ARG...`

Applies defaults, parses the supplied argument vector, validates values and
required declarations, then calls `uniopt_validate`. Supported spellings are
`--long value`, `--long=value`, and `-x value`. Short-option clusters are not
expanded. Duplicate scalars use the last occurrence. Returns 0 or 2. Built-in
help and GUI actions return 0 before required-value and constraint checks;
inspect `UNIOPT_ACTION` immediately after parsing.

### `uniopt_validate`

Validates registered constraints against the current parsed occurrence state.
`uniopt_parse` calls it automatically. It is public for applications that add
explicit occurrence state through a future adapter before validation.

## Reading parsed values

### `uniopt_get ID [OUTPUT_VARIABLE]`

Prints a scalar value with a trailing newline. With `OUTPUT_VARIABLE`, assigns
the value without a subshell or newline loss. Rejects multi-value IDs.

### `uniopt_get_source ID`

Prints one provenance value: `unset`, `default`, `inherited`, `env:VARIABLE`,
`dynamic:FUNCTION`, `cli:SPELLING`, or `positional`.

### `uniopt_get_all ID`

Copies a repeatable or remainder value into `UNIOPT_RESULT`, preserving one
array element per original argument. Replaces the previous result.

### `uniopt_get_unknown`

Copies arguments handled by the `collect` or `stop` policy into
`UNIOPT_RESULT`.

### Compatibility getter names

- `uniopt_value` calls `uniopt_get`.
- `uniopt_provenance` calls `uniopt_get_source`.
- `uniopt_values ID` calls `uniopt_get_all`. The removed second output-array
  argument returns status 2 with a migration diagnostic.

## Generated interfaces

### `uniopt_help`

Writes deterministic terminal usage and option/argument descriptions to
standard output.

### `uniopt_markdown`

Writes a deterministic Markdown option table to standard output.

### `uniopt_json`

Writes a deterministic JSON object with `schema_version: 1`, command metadata,
items, spellings, types, defaults, choices, alias assignments, stable semantic
IDs, constraints, language bindings, and optional presentation metadata in
each item's `ui` object. Dynamic and environment default values remain
unresolved. Bash bindings retain scalar destinations, the unknown-argument
destination, dynamic-default function names, and validator function names.
Alias assignments are ordered arrays so regeneration preserves duplicate
target assignments.

The normalized format is formally described by
[`schema/uniopt.schema.json`](https://bigdft-group.github.io/uniopt/schema/uniopt.schema.json).

### `uniopt_completion [COMMAND [FUNCTION]]`

Writes a Bash completion definition. `COMMAND` defaults to the schema command.
`FUNCTION` defaults to `_uniopt_COMMAND` with hyphens converted to underscores
and must be a Bash identifier. Completion covers option spellings, enum values,
and path values for path-typed options.

## Companion command

`bin/uniopt` exposes renderers, parser-only validation, and the GUI advisor:

```text
uniopt {help|markdown|json|completion} SCHEMA_FILE [SCHEMA_FUNCTION]
uniopt json-to-bash SCHEMA_JSON [SCHEMA_FUNCTION]
uniopt validate SCHEMA_FILE SCHEMA_FUNCTION -- [ARG...]
uniopt gui SCHEMA_FILE SCHEMA_FUNCTION -- PROGRAM [FIXED_ARG...]
```

It sets `UNIOPT_INTROSPECT=1`, sources the trusted schema file, optionally calls
the named registration function, and invokes the selected renderer. It locates
the library in the repository layout, the installed `share/uniopt` layout, or
the explicit `UNIOPT_LIB` path. Schema files supplied to this command are Bash
code and must be trusted.

`json-to-bash` validates normalized UniOpt JSON and writes a deterministic Bash
registration function. It uses Python 3 only at generation time; the generated
file needs only UniOpt and Bash 3.2. Callback names are retained as Bash
bindings, while callback implementations remain application code. See the
[round-trip guide](schema-round-trip.md) for the semantic guarantee and safety
limits.

`validate` runs defaults, parsing, types, custom validators, and constraints
without application domain logic. `gui` fixes the executable before opening a
Tk, Qt, or loopback web advisor, validates the constructed argv, then invokes
that executable directly without a shell. Select a backend with
`UNIOPT_GUI_BACKEND=auto|tk|qt|web`, a web port with `UNIOPT_GUI_PORT`, and
automatic browser opening with `UNIOPT_GUI_OPEN=1`. `UNIOPT_PYTHON` selects the
Python interpreter used for the optional advisor and JSON-to-Bash compiler.
The Bash parser and shell-native help, Markdown, JSON, and completion renderers
do not require Python.

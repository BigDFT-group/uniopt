# UniOpt API and behavior specification

## Scope

UniOpt is a sourced Bash 3.2+ library. One in-memory schema drives parsing,
validation, terminal help, Markdown, JSON, and Bash completion. The schema is
data: declaring or rendering it does not call default or validation functions,
read the environment, or alter application destinations. Dynamic defaults and
custom validators run only in `uniopt_parse`.

The core does not normalize paths, expand comma-separated application values,
load files, or translate values into Docker/Compose arguments. Those are domain
transformations and remain in the calling command.

## Lifecycle

```bash
source /path/to/lib/uniopt.sh

uniopt_reset
uniopt_schema wise-shell \
  --summary "Open a shell in WISE" \
  --unknown error

uniopt_option session.name \
  --long --name --dest OV_NAME --type string --metavar NAME \
  --help "Select the session"

uniopt_positional shell.command \
  --dest SHELL_ARGS --remainder --metavar COMMAND \
  --help "Command and arguments"

uniopt_parse "$@" || exit 2
uniopt_get_all shell.command
SHELL_ARGS=("${UNIOPT_RESULT[@]}")
```

`uniopt_reset` starts a schema. `uniopt_schema COMMAND` sets its command name,
summary, and unknown-option policy. IDs such as `session.name` are stable
semantic identifiers. CLI spellings (`--name`) and shell destinations
(`OV_NAME`) are separate properties and may change independently.

All public core functions start with `uniopt_`; all library-owned environment
and global variables start with `UNIOPT_`.

## Declarations

`uniopt_option ID` accepts:

| Attribute | Meaning |
|---|---|
| `--short -x`, `--long --example` | CLI spelling; at least one is required |
| `--neg-long --no-example` | Negative spelling for a boolean or tri-state |
| `--dest VARIABLE` | Valid scalar or indexed-array destination |
| `--type TYPE` | `string`, `path`, `int`, `integer`, `uint`, `enum`, `boolean`, or `tristate` |
| `--default VALUE` | Static scalar default |
| `--default-fn FUNCTION` | Dynamic default; called as `FUNCTION output_variable` during parsing |
| `--default-env VARIABLE` | Read a dynamic default from an existing shell/environment variable during parsing |
| `--store-const VALUE` | The spelling consumes no argument and stores this value |
| `--repeatable` | Append each occurrence to an indexed array |
| `--required` | Require an explicit CLI occurrence |
| `--internal` | Declare a hidden state target with no CLI spelling |
| `--choice VALUE` | Add an allowed value for an enum; repeat as needed |
| `--validator FUNCTION` | Additional parser-time validator called with the value |
| `--metavar WORD`, `--help TEXT` | Presentation metadata |

Boolean values are the strings `true` and `false`. Tri-state values add the
default state `inherit`, normally declared with `--default inherit`. Positive
and negative spellings set `true` and `false` respectively; if both occur, the
last occurrence wins and provenance identifies it.

`uniopt_alias ID --long SPELLING --set TARGET VALUE [...]` declares a
no-argument action. It can set one or more previously declared option IDs. This
covers `--inner-containers` storing `sidecar` into `container.mode` and compound
actions such as a prune-with-volumes flag enabling both prune values.

`uniopt_positional ID --dest VARIABLE` declares one positional. Add `--required`
for mandatory input. Add `--remainder` for an indexed array that receives all
remaining arguments. A literal `--` ends option parsing and is not stored;
every argument after it is copied byte-for-byte as a distinct array element.

## Parsing and unknown arguments

`uniopt_parse "$@"` never uses `eval`, generated shell, temporary parser files,
or command strings. It accepts `--option value` and `--option=value`; short
options use `-x value`. It deliberately does not infer short-option clusters.

The schema policy is one of:

| Policy | Behavior |
|---|---|
| `error` | Reject an unknown option or surplus positional |
| `collect` | Continue recognizing known options and append every unknown token to `--unknown-dest` |
| `stop` | At the first unknown token, append it and the untouched tail to `--unknown-dest` |

Both non-error policies require `--unknown-dest ARRAY` as compatibility
metadata. Values are retrieved with `uniopt_get_unknown`, which fills
`UNIOPT_RESULT`. `collect` is suitable
for `wise-up`, where Compose arguments may surround known WISE options. `stop`
models commands whose first non-library argument begins another grammar.

Scalar values are assigned only through validated variable names. Multi-value
results remain in indexed internal records and are exposed through a fixed
result array, avoiding dynamic array assignment on Bash 3.2. Empty strings,
whitespace, glob characters, quotes, and embedded newlines remain data. Parser
errors return status 2 and set `UNIOPT_ERROR`.

## Validation, constraints, and provenance

Built-in types are checked before assignment. Enum choices retain their exact
value. A custom validator returns zero to accept and nonzero to reject.

Constraints are declared after their member IDs:

```bash
uniopt_constraint mutex action.client action.client_file action.daemon action.stop
uniopt_constraint one-of action.client action.client_file action.daemon action.stop
uniopt_constraint requires tls.cert tls.enabled
uniopt_constraint conflicts network.host network.publish
```

Constraints concern explicit occurrences, including alias-driven assignments;
defaults do not trigger them. `mutex` means at most one; `one-of` means exactly
one. Both accept any number of IDs. `requires` and `conflicts` accept exactly
two.

`uniopt_get_source ID` reports `default`, `inherited`, `env:VARIABLE`,
`dynamic:FUNCTION`, `cli:--spelling`, `positional`, or `unset`. `uniopt_get ID
[OUTPUT_VARIABLE]` retrieves a scalar. `uniopt_get_all ID` copies a repeatable
or remainder value into the indexed `UNIOPT_RESULT` array. Callers must consume
or copy that array before the next getter call. `uniopt_get_unknown` does the
same for collected unknown arguments.

`uniopt_value` and `uniopt_provenance` remain compatible aliases for the scalar
getters. `uniopt_values ID` remains an alias for `uniopt_get_all ID`; its old
second output-array argument is intentionally rejected because it depended on
Bash 4.3 namerefs.

## Renderers and completion

The following functions inspect schema metadata without resolving defaults or
running validators:

- `uniopt_help` renders terminal usage.
- `uniopt_markdown` renders a Markdown option reference.
- `uniopt_json` emits the versioned JSON schema used by future GUI clients.
- `uniopt_completion [COMMAND [FUNCTION]]` emits a Bash completion definition,
  including enum value completion after the corresponding option.

JSON uses `schema_version: 1`, exposes semantic IDs and CLI spellings separately,
and describes aliases through their `sets` object. Dynamic and environment
defaults are exported by source name and their literal value is `null`, so
introspection cannot cause their side effects.

## ContainerXP compatibility path

ContainerXP's five-field declaration can be translated mechanically after the
core interface stabilizes:

```text
uniopt NAME SHORT LONG DEFAULT HELP
  -> semantic ID derived once and recorded explicitly
  -> --short -SHORT --long --LONG --dest NAME --help HELP
  -> ASSUME_NO  => --type boolean --default false
  -> ASSUME_YES => --type boolean --default true (with a negative spelling chosen by the adapter)
  -> other      => --type string --default DEFAULT
```

The adapter will live separately from `lib/uniopt.sh`, expose the legacy
`uniopt`/`uniopt_parser` names only when sourced, and warn about ambiguous
legacy behavior. In particular, the predecessor loses positional boundaries and
cannot represent values containing spaces reliably. Compatibility therefore
means translating declarations and variables, while new code receives an array
for positionals. The standalone core does not reproduce code generation,
temporary files, `eval`, or the old `UNIOPT_VERBATIM` parser dump.

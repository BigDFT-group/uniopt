# Bash and JSON schema round trip

UniOpt JSON is a normalized interchange representation of a registered command
schema. The companion command can convert a trusted Bash declaration to JSON
and compile that JSON back into Bash declarations:

```bash
./bin/uniopt json mytool-schema.sh mytool_schema >mytool.schema.json
./bin/uniopt json-to-bash mytool.schema.json mytool_schema \
  >mytool-schema.generated.sh
```

The generated file defines the requested registration function. Source the
UniOpt library and that file, then call the function exactly as for a handwritten
schema:

```bash
source /usr/local/share/uniopt/lib/uniopt.sh
source ./mytool-schema.generated.sh
mytool_schema
uniopt_parse "$@" || exit 2
```

Conversion needs Python 3 and only its standard library. The generated schema
has no Python or JSON parser dependency and remains compatible with Bash 3.2.

## What round trip means

The guarantee is semantic rather than textual:

```text
Bash declarations
    -> normalized JSON A
    -> generated Bash declarations
    -> normalized JSON B

JSON A == JSON B
```

Registration order, semantic IDs, spellings, defaults, types, choices,
repeatability, positionals, aliases, constraints, presentation metadata, and
Bash bindings are retained. The parser, help, Markdown, completion, and GUI
continue to consume the same in-memory registry.

The converter does not reconstruct comments, formatting, loops, conditionals,
or helper-function bodies from the original Bash source. It captures the
concrete schema registered during introspection.

## Language bindings

Portable CLI behavior is separate from language-specific names. Schema-level
Bash bindings currently contain the unknown-argument destination:

```json
"bindings": {
  "bash": {
    "unknown_destination": "COMPOSE_ARGS"
  }
}
```

Each item carries its Bash result destination and callback names:

```json
"bindings": {
  "bash": {
    "destination": "JOBS",
    "default_function": null,
    "validator": "validate_positive_jobs"
  }
}
```

The `destination` and `dynamic_default` fields remain in the normalized JSON
for compatibility with current consumers. The compiler requires them to agree
with `bindings.bash`, preventing two conflicting interpretations.

A future Python package can add a sibling binding:

```json
"bindings": {
  "bash": {"destination": "JOBS", "validator": "validate_jobs"},
  "python": {"destination": "jobs", "validator": "validate_jobs"}
}
```

The present Bash exporter naturally emits the Bash projection. The
JSON-to-Bash compiler selects `bindings.bash`; a later Python adapter will
select `bindings.python`. Stable semantic IDs remain the portable interface.

## Callbacks and application code

JSON records callback names, not executable source. If generated declarations
refer to a dynamic default or validator, the application must provide that
function before parsing:

```bash
validate_positive_jobs() {
  (( $1 > 0 ))
}

source ./mytool-schema.generated.sh
mytool_schema
uniopt_parse "$@"
```

This keeps executable code out of the data format. It also gives another
language freedom to bind the same semantic operation to its own implementation.

## Ordered aliases and reserved controls

Alias assignments are arrays rather than JSON objects:

```json
"sets": [
  {"id": "output.mode", "value": "brief"},
  {"id": "output.color", "value": "false"}
]
```

Arrays retain order and repeated assignments to the same target. The last
assignment therefore has the same meaning after regeneration.

The reserved `interface.help` and `interface.gui` entries remain visible in
JSON for introspection. The compiler validates and skips their explicit
generation because `uniopt_schema` registers them automatically.

## Validation and safety

The formal format is published as
[`uniopt.schema.json`](https://bigdft-group.github.io/uniopt/schema/uniopt.schema.json).
The compiler additionally checks duplicate object keys, supported schema
versions, callback and function identifiers, binding consistency, item kinds,
types, UI metadata, and unknown properties.

All generated arguments use literal Bash quoting. Values are never evaluated
or converted through whitespace-delimited strings. Empty strings, spaces,
quotes, dollar signs, command-substitution text, wildcards, brackets,
backslashes, Unicode, and embedded newlines remain data. NUL is rejected
because Bash variables and Unix argument vectors cannot represent it.

## Choosing the authoritative source

A project should choose either the Bash declaration or JSON document as its
editable source and generate the other artifact in CI. Editing both creates an
avoidable merge and synchronization problem. UniOpt supports both directions;
the choice belongs to the application.

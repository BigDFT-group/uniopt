# UniOpt

UniOpt is a declarative command-line option library for Bash 3.2+. One schema
drives parsing, validation, terminal help, Markdown, Bash completion, and JSON
introspection while preserving exact argument boundaries.

Start with the [documentation index](docs/README.md), the
[external-user guide](docs/user-guide.md), and the runnable
[`uniopt-demo`](examples/uniopt-demo/README.md). The complete public contract is
in the [API reference](docs/api-reference.md). Installation choices and the
JSON-to-GUI design are covered in
[installation and GUI integration](docs/installation-and-gui.md).
The published manual is available at
[bigdft-group.github.io/uniopt](https://bigdft-group.github.io/uniopt/), with
[`llms.txt`](https://bigdft-group.github.io/uniopt/llms.txt) and
[`llms-full.txt`](https://bigdft-group.github.io/uniopt/llms-full.txt) at the
site root for coding agents.
The native and generic runner contract is specified in the
[GUI line-advisor design](docs/gui-design.md).
For application packaging, see
[distributing an installable command](docs/distributing-a-script.md).

Launch the schema-generated demo GUI with:

```bash
./examples/uniopt-demo/uniopt-demo --gui
```

To assess migration effort against representative WISE and ContainerXP
interfaces, use the runnable [integration previews](examples/integration-preview/README.md).
They generate completion, Markdown, JSON, and static GUI forms without running
Docker or modifying either source project.

Run the complete syntax, static, and behavior suite with:

```bash
./tests/all.sh
```

Regenerate and verify schema-derived documentation with:

```bash
./scripts/generate-docs
./scripts/check-docs
```

Render any schema file that declares a schema when sourced, or name a function
in a file containing several schemas:

```bash
./bin/uniopt json examples/wise-schemas.sh wise_schema_env
./bin/uniopt help examples/wise-schemas.sh wise_schema_shell
```

Round-trip a declaration through normalized JSON and generate a standalone
Bash registration function:

```bash
./bin/uniopt json examples/uniopt-demo/schema.sh uniopt_demo_schema >demo.schema.json
./bin/uniopt json-to-bash demo.schema.json generated_demo_schema >demo-schema.sh
```

The [round-trip guide](docs/schema-round-trip.md) documents language bindings,
callback handling, exact quoting, and the formal JSON format.

This repository is a standalone design. WISE and ContainerXP are inputs to its
behavior requirements; neither project is modified by this prototype.

CI runs the full suite with current Bash, a checksum-pinned GNU Bash 3.2.57
build, and macOS `/bin/bash`. See
[`docs/bash-3.2-compatibility.md`](docs/bash-3.2-compatibility.md) for the
compatibility policy and result API migration.

Contribution rules are in [CONTRIBUTING.md](CONTRIBUTING.md), and the
[release checklist](docs/releasing.md) describes publication and tagging.

UniOpt is distributed under the [MIT License](LICENSE).

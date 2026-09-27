# Distributing an installable UniOpt command

This guide shows how to package a Bash command so its parser, schema, and tab
completion are installed together. The runnable reference is
[`examples/uniopt-demo`](https://github.com/bigdft-group/uniopt/tree/main/examples/uniopt-demo).

## Recommended project layout

```text
mytool/
├── bin/mytool
├── lib/uniopt.sh
├── schema.sh
├── completion/mytool.bash
└── install
```

Keep the schema in a side-effect-free registration function:

```bash
mytool_schema() {
  uniopt_reset
  uniopt_schema mytool --summary "Example command"
  uniopt_option output.format \
    --long --format --dest FORMAT --type enum --default text \
    --choice text --choice json --metavar FORMAT \
    --help "Output format"
  uniopt_positional input.file \
    --dest INPUT --type path --required --metavar INPUT \
    --help "Input file"
}
```

Generate completion from that same schema:

```bash
bin/uniopt completion schema.sh mytool_schema >completion/mytool.bash
```

Regenerate it whenever the schema changes and compare the committed file in CI.
UniOpt's `scripts/generate-docs --check` pattern shows how.

## Make the executable relocatable

During development, source the repository copy. After installation, find the
application's private data relative to the installed command:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -r "$SCRIPT_DIR/../share/mytool/lib/uniopt.sh" ]]; then
  MYTOOL_LIB="$SCRIPT_DIR/../share/mytool/lib/uniopt.sh"
  MYTOOL_SCHEMA="$SCRIPT_DIR/../share/mytool/schema.sh"
else
  MYTOOL_LIB="$SCRIPT_DIR/../lib/uniopt.sh"
  MYTOOL_SCHEMA="$SCRIPT_DIR/../schema.sh"
fi

source "$MYTOOL_LIB"
source "$MYTOOL_SCHEMA"
mytool_schema
uniopt_parse "$@" || exit 2
if [[ "$UNIOPT_ACTION" == help ]]; then
  uniopt_help
  exit 0
fi
if [[ "$UNIOPT_ACTION" == gui ]]; then
  exec "${UNIOPT_BIN:-uniopt}" gui "$MYTOOL_SCHEMA" mytool_schema -- "$0"
fi
```

Resolve paths from `BASH_SOURCE`, never from the caller's working directory.
`-h`, `--help`, and `--gui` are registered and reserved by `uniopt_schema`, so
the application must not redeclare them. Install the UniOpt companion command
and its `share/uniopt/tools` directory if the packaged command offers the GUI.

## Installer layout

For a user installation with `PREFIX=$HOME/.local`, install:

```text
PREFIX/bin/mytool
PREFIX/share/mytool/schema.sh
PREFIX/share/mytool/lib/uniopt.sh
PREFIX/share/bash-completion/completions/mytool
```

A minimal Bash 3.2-compatible installer follows this pattern:

```bash
PREFIX="${PREFIX:-$HOME/.local}"
DESTDIR="${DESTDIR:-}"

mkdir -p \
  "$DESTDIR$PREFIX/bin" \
  "$DESTDIR$PREFIX/share/mytool/lib" \
  "$DESTDIR$PREFIX/share/bash-completion/completions"

cp bin/mytool "$DESTDIR$PREFIX/bin/mytool"
cp schema.sh "$DESTDIR$PREFIX/share/mytool/schema.sh"
cp lib/uniopt.sh "$DESTDIR$PREFIX/share/mytool/lib/uniopt.sh"
cp completion/mytool.bash \
  "$DESTDIR$PREFIX/share/bash-completion/completions/mytool"
```

Vendoring the UniOpt library with the application pins the parser version and
avoids relying on a machine-wide library search. A system package can instead
declare UniOpt as a dependency and use its shared installation.

## What “automatic completion” means

The generated file registers a completion function with Bash's `complete`
builtin. Installing it does not alter an already-running shell. One of these
must happen:

1. a Bash completion loader scans
   `PREFIX/share/bash-completion/completions/` when a new shell starts; or
2. the user sources the installed file from `~/.bash_profile`.

Portable fallback:

```bash
source "$HOME/.local/share/bash-completion/completions/mytool"
```

After installation or upgrade, start a new Bash or source the file again.
Verify registration with:

```bash
complete -p mytool
```

On macOS, the login shell may be Zsh. UniOpt currently generates Bash
completion, so the user must run an interactive Bash and load the Bash
completion setup. Homebrew's
[shell completion guide](https://docs.brew.sh/Shell-Completion) explains the
system-Bash-compatible loader and profile configuration.

## Package-manager integration

- Homebrew formulae should install the generated file with the formula
  `bash_completion` helper.
- Debian/RPM packages commonly install command completions in their
  distribution's Bash-completion directory.
- Archive installers should prefer the per-user prefix and print the fallback
  `source` command instead of modifying shell startup files silently.

Test the staged layout using `DESTDIR` before publishing. The UniOpt demo test
installs into a temporary staging root, executes the installed command, sources
the installed completion, and exercises enum and option completion.

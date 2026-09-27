# WISE and ContainerXP integration preview

These side-effect-free commands reproduce representative public CLI shapes
from WISE and ContainerXP using UniOpt. They parse and print semantic results;
they do not run Docker, create sessions, remove volumes, or write converted
SDK files. This keeps the examples safe while showing the actual migration
surface.

The reference snapshot and known differences are recorded in
[`docs/integration-reference-audit.md`](../../docs/integration-reference-audit.md).

## Try the command twins

Add the preview directory to `PATH` so completion uses the real command names:

```bash
export PATH="$PWD/examples/integration-preview/bin:$PATH"

wise-env --name research --inner-containers --publish 8888 --no-host-open
wise-up --name research --extra-compose local.yml -- --ansi never
wise-shell --name research -- printf '%s\n' '' 'two words' '*'
bigdftmk --sources '/work/source tree' --image bigdft/sdk:latest -- --version
```

Output uses Bash `%q` formatting so argument boundaries remain visible. An
empty value, for example, appears as `''` and is not lost.

## Activate completion

Generate and source one completion:

```bash
./examples/integration-preview/render completion wise-env >/tmp/wise-env.bash
source /tmp/wise-env.bash
wise-env --pla<TAB>
```

Or use the CI-checked copies after running `./scripts/generate-integration-docs`:

```bash
source docs/generated/integration-preview/wise-env.bash
source docs/generated/integration-preview/bigdftmk.bash
```

Because completion is registered for `wise-env` and `bigdftmk`, those names
must resolve through `PATH`; invoking a preview by a longer repository path
does not change Bash's registered command name.

## Generate GUI forms

Render any schema to a standalone form:

```bash
./examples/integration-preview/render gui wise-env > /tmp/wise-env.html
./examples/integration-preview/render gui laramk > /tmp/laramk.html
```

The static form shows groups, typed controls, repeatable arguments, aliases,
positionals, defaults, and constraints. Each executable twin also accepts
`--gui`, which opens the generic advisor and executes that safe preview twin:

```bash
examples/integration-preview/bin/wise-env --gui
examples/integration-preview/bin/dockerfile-to-wise-sdk --gui
```

## Inspect all generated interfaces

```bash
./examples/integration-preview/render help wise-down
./examples/integration-preview/render markdown wise-host-open
./examples/integration-preview/render json dockerfile-to-wise-sdk
```

Available command twins are:

- WISE: `wise-env`, `wise-up`, `wise-down`, `wise-shell`, `wise-host-open`, and
  `dockerfile-to-wise-sdk`;
- ContainerXP: `bigdftmk`, `laramk`, and `latexmk`.

The repetitive WISE `wise-check`, `wise-gpu-check`, and `wise-sudo` interfaces
are represented by the same shared session/Compose declarations used here.
Adding their domain behavior during migration does not require a new parser
feature.

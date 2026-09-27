# Contributing to UniOpt

UniOpt targets Bash 3.2 and current Bash. Keep schema registration free of
application side effects and preserve each argument as its own array element.
Parser code must not use `eval`, generated parser scripts, or command strings.

Before submitting a change, run:

```bash
./scripts/generate-docs
./scripts/generate-integration-docs
./scripts/generate-llms
./tests/all.sh
```

Generated files belong in the change. `./scripts/check-docs` verifies that they
match their schemas and that every public declaration attribute is documented.
CI repeats the complete suite with current Bash, pinned GNU Bash 3.2.57, and
macOS system Bash 3.2.

Changes to the public API should update `docs/api-reference.md`, the user guide,
tests for current and minimum Bash, and compatibility notes when behavior or a
getter contract changes.

#!/usr/bin/env bash
# This file intentionally contains only Bash 3.2 syntax. It was added before
# the implementation refactor and fails against the Bash 4.3-only core.
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/uniopt.sh"
source "$ROOT_DIR/examples/wise-schemas.sh"

failures=0
check() { if "$@"; then :; else failures=$((failures + 1)); fi; }

wise_schema_shell
value=$'line one\nline two'
uniopt_parse -- printf '' 'two words' '*' '?' '[x]' '$HOME' 'a\b' "$value" --leading
uniopt_get_all shell.command
check test "${#UNIOPT_RESULT[@]}" -eq 10
check test "${UNIOPT_RESULT[1]}" = ''
check test "${UNIOPT_RESULT[8]}" = "$value"
check test "${UNIOPT_RESULT[9]}" = --leading

wise_schema_env
uniopt_parse --extra-compose one --extra-compose 'two files' --inner-containers
uniopt_get_all compose.extra
check test "${UNIOPT_RESULT[0]}" = one
check test "${UNIOPT_RESULT[1]}" = 'two files'
check test "$(uniopt_get container.mode)" = sidecar

exit "$failures"

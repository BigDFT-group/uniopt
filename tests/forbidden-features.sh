#!/usr/bin/env bash
set -u
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
files=(
  "$ROOT_DIR/lib/uniopt.sh"
  "$ROOT_DIR/bin/uniopt"
  "$ROOT_DIR/examples/wise-schemas.sh"
  "$ROOT_DIR/examples/uniopt-demo/schema.sh"
  "$ROOT_DIR/examples/uniopt-demo/uniopt-demo"
  "$ROOT_DIR/examples/uniopt-demo/install"
  "$ROOT_DIR/examples/integration-preview/schemas.sh"
  "$ROOT_DIR/examples/integration-preview/preview-command"
  "$ROOT_DIR/examples/integration-preview/render"
  "$ROOT_DIR/scripts/generate-docs"
  "$ROOT_DIR/scripts/check-docs"
  "$ROOT_DIR/scripts/install-uniopt"
)
for file in "$ROOT_DIR"/examples/integration-preview/bin/*; do files[${#files[@]}]="$file"; done
status=0
if grep -En '(^|[;[:space:]])(local|declare)[[:space:]]+-[^[:space:]]*[An][[:space:]]' "${files[@]}"; then status=1; fi
if grep -En '(^|[;[:space:]])(mapfile|readarray|coproc|eval)([;[:space:]]|$)|&>>|\|&|\[[[:space:]]*-[0-9]+[[:space:]]*\]' "${files[@]}"; then status=1; fi
if grep -Fn '${value,,}' "${files[@]}" || grep -Fn '${value^^}' "${files[@]}" || grep -En '\[\[[^]]+[[:space:]]-v[[:space:]]' "${files[@]}"; then status=1; fi
if (( status != 0 )); then printf 'Bash 4+ or forbidden parser construct found\n' >&2; exit 1; fi
printf 'Bash 3.2 forbidden-feature audit passed\n'

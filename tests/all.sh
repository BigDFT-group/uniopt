#!/usr/bin/env bash
set -u
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for file in "$ROOT_DIR"/lib/*.sh "$ROOT_DIR"/examples/*.sh \
  "$ROOT_DIR"/examples/uniopt-demo/schema.sh \
  "$ROOT_DIR"/examples/uniopt-demo/uniopt-demo \
  "$ROOT_DIR"/examples/uniopt-demo/install \
  "$ROOT_DIR"/examples/integration-preview/schemas.sh \
  "$ROOT_DIR"/examples/integration-preview/preview-command \
  "$ROOT_DIR"/examples/integration-preview/render \
  "$ROOT_DIR"/examples/integration-preview/bin/* \
  "$ROOT_DIR"/tests/*.sh "$ROOT_DIR"/bin/uniopt "$ROOT_DIR"/ci/*.sh \
  "$ROOT_DIR"/scripts/*; do
  [[ -f "$file" ]] || continue
  [[ "$(head -n 1 "$file")" == *bash* ]] || continue
  "$BASH" -n "$file" || exit 1
done
"$BASH" "$ROOT_DIR/tests/forbidden-features.sh" || exit 1
"$BASH" "$ROOT_DIR/scripts/check-docs" || exit 1
python3 "$ROOT_DIR/tests/documentation-links.py" || exit 1
"$BASH" "$ROOT_DIR/tests/run.sh" || exit 1
"$BASH" "$ROOT_DIR/tests/bash32-contract.sh" || exit 1
"$BASH" "$ROOT_DIR/tests/extended.sh" || exit 1
"$BASH" "$ROOT_DIR/tests/documentation.sh" || exit 1
"$BASH" "$ROOT_DIR/tests/integration-preview.sh" || exit 1
python3 "$ROOT_DIR/tests/gui-advisor.py" || exit 1

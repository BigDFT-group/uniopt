#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/uniopt.sh"
source "$ROOT_DIR/examples/integration-preview/schemas.sh"
tests=0 failures=0
ok() { tests=$((tests + 1)); printf 'ok %d - %s\n' "$tests" "$1"; }
not_ok() { tests=$((tests + 1)); failures=$((failures + 1)); printf 'not ok %d - %s\n' "$tests" "$1"; }
assert_eq() { if [[ "$1" == "$2" ]]; then ok "$3"; else not_ok "$3"; fi; }
assert_result() {
  local name="$1" count i=0; shift; count=$#
  if (( ${#UNIOPT_RESULT[@]} != count )); then not_ok "$name"; return; fi
  while (( $# )); do [[ "${UNIOPT_RESULT[$i]}" == "$1" ]] || { not_ok "$name"; return; }; i=$((i + 1)); shift; done
  ok "$name"
}

preview_schema_wise_env
uniopt_parse --name 'research one' --publish '' --publish '127.0.0.1:9000:8000' --inner-containers --no-host-open
assert_eq 'research one' "$OV_NAME" "WISE session name preserves spaces"
uniopt_get_all network.publish; assert_result "WISE publish remains repeatable" '' '127.0.0.1:9000:8000'
assert_eq sidecar "$CONTAINER_MODE" "WISE inner-containers alias stores sidecar"
assert_eq false "$HOST_OPEN" "WISE negative host-open is explicit"

preview_schema_wise_down
uniopt_parse --prune-inner-container-volumes
assert_eq true "$PRUNE_INNER" "WISE compound prune enables pruning"
assert_eq true "$PRUNE_VOLUMES" "WISE compound prune enables volume pruning"

preview_schema_wise_host_open
uniopt_parse --client https://example.test --stop >/dev/null 2>&1
assert_eq 2 "$?" "WISE host-open actions are mutually exclusive"

preview_schema_wise_shell
newline=$'line one\nline two'
uniopt_parse --name demo -- printf '%s' '' 'two words' '*' "$newline"
uniopt_get_all shell.command; assert_result "WISE shell preserves exact remainder argv" printf '%s' '' 'two words' '*' "$newline"

preview_schema_wise_up
uniopt_parse --name demo --project-name 'project one' --ansi never subcommand --build
uniopt_get_unknown; assert_result "WISE up preserves passthrough elements" --project-name 'project one' --ansi never subcommand
assert_eq true "$DO_BUILD" "WISE up parses known options after passthrough"

preview_schema_dockerfile_to_wise_sdk
uniopt_parse --output-dir 'output tree' Dockerfile
assert_eq 'output tree' "$OUTPUT_DIR" "converter output path preserves spaces"
assert_eq Dockerfile "$DOCKERFILE" "converter required positional parses"

BIGDFT_SUITE_SOURCES='/source tree'; export BIGDFT_SUITE_SOURCES
preview_schema_bigdftmk
uniopt_parse -i custom/sdk -p 8888 -- --flag '' 'two words'
assert_eq '/source tree' "$SOURCEDIR" "ContainerXP environment default is resolved at parse time"
assert_eq 'dynamic:preview_bigdft_sources' "$(uniopt_get_source source.bigdft)" "ContainerXP compatibility default provenance is distinguishable"
uniopt_get_unknown; assert_result "ContainerXP passthrough boundaries are retained" --flag '' 'two words'

preview_schema_laramk
uniopt_parse -l '/lara source' --lara-sources '/new lara source'
assert_eq '/new lara source' "$LARA_SOURCE" "laramk migration spelling is usable"

commands=(wise-env wise-up wise-down wise-shell wise-host-open dockerfile-to-wise-sdk bigdftmk laramk latexmk)
for command in "${commands[@]}"; do
  UNIOPT_PREVIEW_COMMAND="$command" integration_preview_schema || { not_ok "$command schema registers"; continue; }
  json="$(uniopt_json)"; completion="$(uniopt_completion)"
  if printf '%s' "$json" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["command"] and all("ui" in x for x in d["items"])'; then ok "$command JSON and GUI metadata"; else not_ok "$command JSON and GUI metadata"; fi
  if "$BASH" -n <<<"$completion"; then ok "$command completion syntax"; else not_ok "$command completion syntax"; fi
done

html="$($ROOT_DIR/examples/integration-preview/render gui wise-env)"
[[ "$html" == *'network.publish'* && "$html" == *'Add value'* ]] && ok "WISE schema renders as GUI" || not_ok "WISE schema renders as GUI"

printf '1..%d\n' "$tests"
(( failures == 0 ))

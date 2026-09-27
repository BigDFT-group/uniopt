#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/uniopt.sh
source "$ROOT_DIR/lib/uniopt.sh"
# shellcheck source=../examples/wise-schemas.sh
source "$ROOT_DIR/examples/wise-schemas.sh"

tests=0
failures=0

ok() { tests=$((tests + 1)); printf 'ok %d - %s\n' "$tests" "$1"; }
not_ok() { tests=$((tests + 1)); failures=$((failures + 1)); printf 'not ok %d - %s\n' "$tests" "$1"; }
assert_eq() {
  local expected="$1" actual="$2" name="$3"
  if [[ "$actual" == "$expected" ]]; then ok "$name"; else not_ok "$name (expected $(printf %q "$expected"), got $(printf %q "$actual"))"; fi
}
assert_status() {
  local expected="$1" actual="$2" name="$3"
  if [[ "$actual" -eq "$expected" ]]; then ok "$name"; else not_ok "$name (expected status $expected, got $actual)"; fi
}
assert_result() {
  local name="$1" expected_count i=0
  shift; expected_count=$#
  if (( ${#UNIOPT_RESULT[@]} != expected_count )); then not_ok "$name (array lengths differ)"; return; fi
  while (( $# )); do
    if [[ "${UNIOPT_RESULT[$i]}" != "$1" ]]; then not_ok "$name (element $i differs)"; return; fi
    i=$((i + 1)); shift
  done
  ok "$name"
}

# Shared values and repeatable arrays.
wise_schema_env
uniopt_parse --name 'research one' --env-file '/tmp/e f' --extra-compose a.yml --extra-compose 'b file.yml' --publish 8888 --publish '127.0.0.1:9000:8000'
assert_status 0 $? "shared WISE options parse"
assert_eq 'research one' "$OV_NAME" "scalar boundaries are retained"
uniopt_get_all compose.extra; assert_result "extra-compose is repeatable" a.yml 'b file.yml'
uniopt_get_all network.publish; assert_result "publish is repeatable" 8888 '127.0.0.1:9000:8000'

# Inherited tri-state and last occurrence wins.
wise_schema_env
uniopt_parse
assert_eq inherit "$HOST_OPEN" "tri-state defaults to inherit"
assert_eq inherited "$(uniopt_provenance host.open)" "inherited default provenance"
uniopt_parse --host-open --no-host-open
assert_eq false "$HOST_OPEN" "negative tri-state spelling wins"
assert_eq 'cli:--no-host-open' "$(uniopt_provenance host.open)" "CLI spelling is provenance"

# A store-constant alias updates another semantic option.
wise_schema_env
uniopt_parse --inner-containers
assert_eq sidecar "$CONTAINER_MODE" "inner-containers stores sidecar"
assert_eq 'cli:--inner-containers' "$(uniopt_provenance container.mode)" "alias provenance reaches target"

# Compound action sets both prune states.
wise_schema_down
uniopt_parse --prune-inner-container-volumes
assert_eq true "$PRUNE_INNER" "compound prune enables pruning"
assert_eq true "$PRUNE_VOLUMES" "compound prune enables volume pruning"

# Action modes are mutually exclusive.
wise_schema_host_open
uniopt_parse --client https://example.test
assert_status 0 $? "one host-open action is valid"
uniopt_parse --client https://example.test --stop >/dev/null 2>&1
assert_status 2 $? "host-open action modes are exclusive"

# Remainder values preserve exact argv boundaries, including empty and newline values.
wise_schema_shell
newline_value=$'line one\nline two'
uniopt_parse --name demo -- printf '%s' '' 'a b' '*' "$newline_value"
assert_status 0 $? "remainder parses"
uniopt_get_all shell.command; assert_result "remainder preserves exact arguments" printf '%s' '' 'a b' '*' "$newline_value"

# Unknown Compose arguments are collected while later known WISE options still parse.
wise_schema_up
uniopt_parse --project-name 'p one' --name demo --ansi never subcommand --build
assert_status 0 $? "passthrough policy parses"
assert_eq demo "$OV_NAME" "known option after passthrough is recognized"
assert_eq true "$DO_BUILD" "known flag after passthrough is recognized"
uniopt_get_unknown; assert_result "Compose passthrough boundaries are retained" --project-name 'p one' --ansi never subcommand

# Required option and positional input.
wise_schema_converter
uniopt_parse --output-dir out Dockerfile
assert_status 0 $? "required converter inputs parse"
assert_eq Dockerfile "$DOCKERFILE" "required positional is assigned"
uniopt_parse --output-dir out >/dev/null 2>&1
assert_status 2 $? "missing required positional is rejected"
uniopt_parse Dockerfile >/dev/null 2>&1
assert_status 2 $? "missing required option is rejected"

# Type validation and --long=value.
uniopt_reset; uniopt_schema typed
uniopt_option jobs.count --long --jobs --dest JOBS --type uint --default 1
uniopt_parse --jobs=8
assert_eq 8 "$JOBS" "long equals syntax parses typed value"
uniopt_parse --jobs nope >/dev/null 2>&1
assert_status 2 $? "invalid typed value is rejected"

# Dynamic defaults are never called by introspection.
DEFAULT_CALLS=0
test_dynamic_default() { DEFAULT_CALLS=$((DEFAULT_CALLS + 1)); printf -v "$1" '%s' dynamic-value; }
uniopt_reset; uniopt_schema inspect
uniopt_option value.dynamic --long --value --dest DYNAMIC_VALUE --default-fn test_dynamic_default
uniopt_help >/dev/null; uniopt_markdown >/dev/null; uniopt_json >/dev/null; uniopt_completion >/dev/null
assert_eq 0 "$DEFAULT_CALLS" "schema introspection is side-effect-free"
json="$(uniopt_json)"; completion="$(uniopt_completion)"
uniopt_parse
assert_eq 1 "$DEFAULT_CALLS" "dynamic default runs during parsing"
assert_eq dynamic-value "$DYNAMIC_VALUE" "dynamic default assigns value"

# Rendered artifacts are structurally usable.
if command -v python3 >/dev/null 2>&1 && printf '%s' "$json" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert any(x["id"] == "value.dynamic" for x in d["items"])'; then ok "JSON export is valid and contains semantic IDs"; else not_ok "JSON export is valid and contains semantic IDs"; fi
if bash -n <<<"$completion"; then ok "completion output is valid Bash"; else not_ok "completion output is valid Bash"; fi
help_text="$(uniopt_help)"; markdown_text="$(uniopt_markdown)"
[[ "$help_text" == *'--value VALUE'* ]] && ok "terminal help derives from schema" || not_ok "terminal help derives from schema"
[[ "$markdown_text" == *'value.dynamic'* || "$markdown_text" == *'--value VALUE'* ]] && ok "Markdown derives from schema" || not_ok "Markdown derives from schema"
wise_schema_env; enum_completion="$(uniopt_completion)"
if bash -n <<<"$enum_completion"; then ok "enum completion output is valid Bash"; else not_ok "enum completion output is valid Bash"; fi

# Unknown policy and literal payloads cannot become shell code.
marker="$ROOT_DIR/tests/eval-marker"
payload='$(touch tests/eval-marker)'
uniopt_reset; uniopt_schema safe
uniopt_option safe.value --long --value --dest SAFE_VALUE
uniopt_parse --value "$payload"
assert_eq "$payload" "$SAFE_VALUE" "shell-looking input remains data"
[[ ! -e "$marker" ]] && ok "parser does not evaluate input" || not_ok "parser does not evaluate input"
uniopt_parse --wat >/dev/null 2>&1
assert_status 2 $? "unknown options are rejected by default"

printf '1..%d\n' "$tests"
(( failures == 0 ))

#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/uniopt.sh"
source "$ROOT_DIR/examples/wise-schemas.sh"

tests=0; failures=0
ok() { tests=$((tests + 1)); printf 'ok %d - %s\n' "$tests" "$1"; }
not_ok() { tests=$((tests + 1)); failures=$((failures + 1)); printf 'not ok %d - %s\n' "$tests" "$1"; }
assert_eq() { if [[ "$1" == "$2" ]]; then ok "$3"; else not_ok "$3 (expected $(printf %q "$1"), got $(printf %q "$2"))"; fi; }
assert_status() { if [[ "$1" -eq "$2" ]]; then ok "$3"; else not_ok "$3 (expected status $1, got $2)"; fi; }
assert_result() {
  local name="$1" count i=0; shift; count=$#
  if (( ${#UNIOPT_RESULT[@]} != count )); then not_ok "$name (expected $count elements, got ${#UNIOPT_RESULT[@]})"; return; fi
  while (( $# )); do [[ "${UNIOPT_RESULT[$i]}" == "$1" ]] || { not_ok "$name (element $i differs)"; return; }; i=$((i + 1)); shift; done
  ok "$name"
}
capture_failure() {
  local output_file status
  output_file="$(mktemp "${TMPDIR:-/tmp}/uniopt-error.XXXXXX")"
  "$@" >"$output_file" 2>&1; status=$?
  UNIOPT_TEST_ERROR="$(<"$output_file")"; rm -f "$output_file"; return "$status"
}

# Core spelling behavior and duplicate scalar policy.
uniopt_reset; uniopt_schema basic
uniopt_option value.name --short -n --long --name --dest NAME --default default-name
uniopt_option feature.color --long --color --neg-long --no-color --dest COLOR --type boolean --default false
uniopt_parse --name 'two words' --color
assert_eq 'two words' "$NAME" "--long value"
assert_eq true "$COLOR" "positive boolean"
uniopt_parse --name=equals; assert_eq equals "$NAME" "--long=value"
uniopt_parse -n short; assert_eq short "$NAME" "short option"
uniopt_parse --name first --name second; assert_eq second "$NAME" "duplicate scalar uses last value"
uniopt_parse --color --no-color; assert_eq false "$COLOR" "negative boolean form"

# Required and optional positionals.
uniopt_reset; uniopt_schema positionals
uniopt_positional input.file --dest INPUT --type path --required --metavar INPUT
uniopt_positional output.file --dest OUTPUT --type path --metavar OUTPUT
uniopt_parse in.txt
assert_eq in.txt "$INPUT" "required positional"
assert_eq '' "$OUTPUT" "optional positional defaults empty"
uniopt_parse >/dev/null 2>&1; assert_status 2 $? "required positional failure"

# All special characters and Unicode survive as independent remainder elements.
wise_schema_shell
newline_value=$'line one\nline two'; unicode_value=$'caf\303\251-\342\230\203'
uniopt_parse -- printf '' 'two words' '*' '?' '[abc]' '$HOME' 'a\b' '"quoted"' "$unicode_value" "$newline_value" --leading
uniopt_get_all shell.command
assert_result "argument integrity" printf '' 'two words' '*' '?' '[abc]' '$HOME' 'a\b' '"quoted"' "$unicode_value" "$newline_value" --leading

# Unknown error, collect, and stop policies.
uniopt_reset; uniopt_schema unknown-error --unknown error
uniopt_parse --wat >/dev/null 2>&1; assert_status 2 $? "unknown error policy"
uniopt_reset; uniopt_schema unknown-collect --unknown collect --unknown-dest LEGACY_UNKNOWN
uniopt_option known.value --long --known --dest KNOWN
uniopt_parse --x 'x value' --known yes tail --y
uniopt_get_unknown; assert_result "unknown collect policy" --x 'x value' tail --y
assert_eq yes "$KNOWN" "collect recognizes later known options"
uniopt_reset; uniopt_schema unknown-stop --unknown stop --unknown-dest LEGACY_UNKNOWN
uniopt_option known.value --long --known --dest KNOWN
uniopt_parse --known before --x 'x value' --known after
uniopt_get_unknown; assert_result "unknown stop policy" --x 'x value' --known after
assert_eq before "$KNOWN" "stop leaves later known option untouched"

# Useful intentional failures under nounset.
uniopt_reset; uniopt_schema errors
uniopt_option output.dir --long --output-dir --dest OUTPUT_DIR --required
capture_failure uniopt_parse --output-dir; status=$?
assert_status 2 "$status" "missing option value"
[[ "$UNIOPT_TEST_ERROR" == *'--output-dir'* && "$UNIOPT_TEST_ERROR" != *'unbound variable'* ]] && ok "missing-value diagnostic" || not_ok "missing-value diagnostic"
capture_failure uniopt_parse; status=$?
assert_status 2 "$status" "required option failure"
[[ "$UNIOPT_TEST_ERROR" == *'output.dir'* && "$UNIOPT_TEST_ERROR" != *'unbound variable'* ]] && ok "required-option diagnostic" || not_ok "required-option diagnostic"

# Enum and callback validation.
validate_even() { (( $1 % 2 == 0 )); }
uniopt_reset; uniopt_schema validation
uniopt_option mode --long --mode --dest MODE --type enum --choice one --choice two
uniopt_option count --long --count --dest COUNT --type uint --validator validate_even
uniopt_parse --mode bad >/dev/null 2>&1; assert_status 2 $? "enum failure"
uniopt_parse --mode one --count 3 >/dev/null 2>&1; assert_status 2 $? "custom validator failure"
uniopt_parse --mode two --count 4; assert_status 0 $? "validator success"

# Conflicts, dependencies, at-most-one, and exactly-one constraints.
constraint_schema() {
  uniopt_reset; uniopt_schema constraints
  uniopt_option a --long --a --dest A --type boolean --default false
  uniopt_option b --long --b --dest B --type boolean --default false
  uniopt_option c --long --c --dest C --type boolean --default false
}
constraint_schema; uniopt_constraint conflicts a b; uniopt_parse --a --b >/dev/null 2>&1; assert_status 2 $? "conflicts constraint"
constraint_schema; uniopt_constraint requires a b; uniopt_parse --a >/dev/null 2>&1; assert_status 2 $? "requires constraint"
constraint_schema; uniopt_constraint mutex a b c; uniopt_parse --a --c >/dev/null 2>&1; assert_status 2 $? "mutex constraint"
constraint_schema; uniopt_constraint one-of a b c; uniopt_parse >/dev/null 2>&1; assert_status 2 $? "one-of requires one"
uniopt_parse --b; assert_status 0 $? "one-of accepts exactly one"

# Literal, inherited, environment, callback, and explicit provenance.
DEFAULT_CALLS=0
default_callback() { DEFAULT_CALLS=$((DEFAULT_CALLS + 1)); printf -v "$1" '%s' callback-value; }
UNIOPT_TEST_ENV='environment value'; export UNIOPT_TEST_ENV
uniopt_reset; uniopt_schema defaults
uniopt_option literal --long --literal --dest LITERAL --default literal-value
uniopt_option inherited --long --inherited --neg-long --no-inherited --dest INHERITED --type tristate --default inherit
uniopt_option environment --long --environment --dest ENVIRONMENT --default-env UNIOPT_TEST_ENV
uniopt_option callback --long --callback --dest CALLBACK --default-fn default_callback
uniopt_help >/dev/null; uniopt_markdown >/dev/null; uniopt_json >/dev/null; uniopt_completion >/dev/null
assert_eq 0 "$DEFAULT_CALLS" "introspection has no default side effects"
uniopt_parse
assert_eq default "$(uniopt_get_source literal)" "literal provenance"
assert_eq inherited "$(uniopt_get_source inherited)" "inherited provenance"
assert_eq 'env:UNIOPT_TEST_ENV' "$(uniopt_get_source environment)" "environment provenance"
assert_eq 'dynamic:default_callback' "$(uniopt_get_source callback)" "callback provenance"
uniopt_parse --literal explicit
assert_eq 'cli:--literal' "$(uniopt_get_source literal)" "explicit provenance"

# Optional GUI metadata is deterministic, side-effect-free, and validated.
uniopt_reset; uniopt_schema gui-metadata
uniopt_option count --long --count --dest COUNT --type uint \
  --ui-label Count --ui-group Runtime --ui-control number --ui-placeholder N \
  --ui-advanced --ui-order 7 --ui-min 1 --ui-max 9 --ui-step 2
uniopt_positional input --dest INPUT --ui-label Input --ui-control file --ui-order 1
json_one="$(uniopt_json)"
if command -v python3 >/dev/null 2>&1 && printf '%s' "$json_one" | python3 -c 'import json,sys; d=json.load(sys.stdin); a={x["id"]:x for x in d["items"]}; assert a["count"]["ui"] == {"label":"Count","group":"Runtime","control":"number","placeholder":"N","advanced":True,"order":7,"min":"1","max":"9","step":"2","file_mode":"auto"}; assert a["input"]["ui"]["control"] == "file"'; then ok "JSON exports GUI presentation metadata"; else not_ok "JSON exports GUI presentation metadata"; fi
uniopt_reset; uniopt_schema bad-gui
uniopt_option bad --long --bad --dest BAD --ui-control command >/dev/null 2>&1; assert_status 2 $? "invalid GUI control is rejected"
uniopt_reset; uniopt_schema bad-gui-order
uniopt_positional bad --dest BAD --ui-order first >/dev/null 2>&1; assert_status 2 $? "invalid GUI order is rejected"
uniopt_reset; uniopt_schema bad-gui-path
uniopt_option bad --long --bad --dest BAD --ui-file-mode open >/dev/null 2>&1; assert_status 2 $? "file mode requires a path type"

# Help and GUI are native reserved actions and bypass required-value checks.
uniopt_reset; uniopt_schema builtins
uniopt_positional required.input --dest REQUIRED_INPUT --required
uniopt_parse --help; assert_status 0 $? "built-in help bypasses required positionals"
assert_eq help "$UNIOPT_ACTION" "built-in help reports its action"
uniopt_parse --gui; assert_status 0 $? "built-in GUI bypasses required positionals"
assert_eq gui "$UNIOPT_ACTION" "built-in GUI reports its action"
uniopt_option bad.help --long --help --dest BAD >/dev/null 2>&1; assert_status 2 $? "applications cannot redefine --help"
uniopt_option bad.gui --long --gui --dest BAD >/dev/null 2>&1; assert_status 2 $? "applications cannot redefine --gui"

# Generated interfaces are deterministic and derive stable IDs from the schema.
uniopt_reset; uniopt_schema defaults
uniopt_option literal --long --literal --dest LITERAL --default literal-value
uniopt_option inherited --long --inherited --neg-long --no-inherited --dest INHERITED --type tristate --default inherit
uniopt_option environment --long --environment --dest ENVIRONMENT --default-env UNIOPT_TEST_ENV
uniopt_option callback --long --callback --dest CALLBACK --default-fn default_callback
json_one="$(uniopt_json)"; json_two="$(uniopt_json)"; help_one="$(uniopt_help)"; help_two="$(uniopt_help)"; completion_one="$(uniopt_completion)"; completion_two="$(uniopt_completion)"
assert_eq "$json_one" "$json_two" "JSON is deterministic"
assert_eq "$help_one" "$help_two" "help is deterministic"
assert_eq "$completion_one" "$completion_two" "completion is deterministic"
if command -v python3 >/dev/null 2>&1 && printf '%s' "$json_one" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert [x["id"] for x in d["items"]] == ["interface.help", "interface.gui", "literal", "inherited", "environment", "callback"]'; then ok "JSON has stable semantic IDs"; else not_ok "JSON has stable semantic IDs"; fi
if "$BASH" -n <<<"$completion_one"; then ok "completion is valid Bash"; else not_ok "completion is valid Bash"; fi
wise_schema_env; completion_one="$(uniopt_completion)"
[[ "$completion_one" == *'compgen -W'* && "$completion_one" == *'compgen -f'* && "$completion_one" == *'--container-mode'* ]] && ok "completion covers options, enums, and paths" || not_ok "completion covers options, enums, and paths"
wise_schema_converter; completion_one="$(uniopt_completion)"
if "$BASH" -n <<<"$completion_one"; then ok "path positional does not create an empty completion case"; else not_ok "path positional does not create an empty completion case"; fi
marker_dir="$(mktemp -d "${TMPDIR:-/tmp}/uniopt-introspection.XXXXXX")"; marker="$marker_dir/side-effect"
UNIOPT_SIDE_EFFECT_MARKER="$marker" "$BASH" "$ROOT_DIR/bin/uniopt" json "$ROOT_DIR/tests/fixtures/introspection-schema.sh" uniopt_introspection_fixture >/dev/null
[[ ! -e "$marker" ]] && ok "CLI introspection precedes application side effects" || not_ok "CLI introspection precedes application side effects"
rmdir "$marker_dir"

# Application-looking payloads are data, and set -e callers can handle errors.
payload='$(touch tests/eval-marker); * ? [x] $HOME \'
uniopt_reset; uniopt_schema safe; uniopt_option safe.value --long --value --dest SAFE_VALUE
uniopt_parse --value "$payload"; assert_eq "$payload" "$SAFE_VALUE" "shell-looking value remains data"
[[ ! -e "$ROOT_DIR/tests/eval-marker" ]] && ok "parser does not evaluate values" || not_ok "parser does not evaluate values"
if ( set -e; uniopt_parse --value ok; [[ "$SAFE_VALUE" == ok ]] ); then ok "successful parse under set -e"; else not_ok "successful parse under set -e"; fi
if ( set -e; if uniopt_parse --bad >/dev/null 2>&1; then exit 1; fi ); then ok "intentional failure under set -e"; else not_ok "intentional failure under set -e"; fi

# Parsing has no shared files and independent processes can run concurrently.
pids=(); i=0
while (( i < 8 )); do
  ( source "$ROOT_DIR/lib/uniopt.sh"; uniopt_schema concurrent; uniopt_option value --long --value --dest VALUE; uniopt_parse --value "$i"; [[ "$(uniopt_get value)" == "$i" ]] ) &
  pids[$i]=$!; i=$((i + 1))
done
concurrent_status=0; i=0; while (( i < 8 )); do wait "${pids[$i]}" || concurrent_status=1; i=$((i + 1)); done
assert_status 0 "$concurrent_status" "concurrent parser instances"

printf '1..%d\n' "$tests"
(( failures == 0 ))

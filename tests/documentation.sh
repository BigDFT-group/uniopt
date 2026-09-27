#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEMO="$ROOT_DIR/examples/uniopt-demo/uniopt-demo"
failures=0

help_output="$($DEMO --help)" || failures=$((failures + 1))
[[ "$help_output" == *'--style STYLE'* && "$help_output" == *'RECIPIENT'* ]] || failures=$((failures + 1))

demo_output="$($DEMO --quick --tag docs --tag 'two words' Ada -- '' '*' '$HOME')" || failures=$((failures + 1))
[[ "$demo_output" == *'HI ADA'* && "$demo_output" == *'[tags: docs two words]'* && "$demo_output" == *'<> <*> <$HOME>'* ]] || failures=$((failures + 1))

$DEMO --jobs 0 Ada >/dev/null 2>&1 && failures=$((failures + 1))

source "$ROOT_DIR/examples/uniopt-demo/completion/uniopt-demo.bash"
COMP_WORDS=(uniopt-demo --style f); COMP_CWORD=2; _uniopt_uniopt_demo
[[ " ${COMPREPLY[*]} " == *' friendly '* && " ${COMPREPLY[*]} " == *' formal '* ]] || failures=$((failures + 1))
COMP_WORDS=(uniopt-demo --st); COMP_CWORD=1; _uniopt_uniopt_demo
[[ " ${COMPREPLY[*]} " == *' --style '* ]] || failures=$((failures + 1))

html_file="$(mktemp "${TMPDIR:-/tmp}/uniopt-demo.XXXXXX.html")"
python3 "$ROOT_DIR/tools/uniopt-json-to-html" "$ROOT_DIR/docs/generated/uniopt-demo.schema.json" >"$html_file" || failures=$((failures + 1))
grep -Fq 'const schema=' "$html_file" || failures=$((failures + 1))
grep -Fq 'greeting.style' "$html_file" || failures=$((failures + 1))
grep -Fq "['--',...remainders]" "$html_file" || failures=$((failures + 1))
grep -Fq 'Add value' "$html_file" || failures=$((failures + 1))
python3 "$ROOT_DIR/tools/uniopt-json-to-html" --submit-url http://127.0.0.1/run "$ROOT_DIR/docs/generated/uniopt-demo.schema.json" >"$html_file" || failures=$((failures + 1))
grep -Fq 'http://127.0.0.1/run' "$html_file" || failures=$((failures + 1))
grep -Fq '<h2>Command line</h2>' "$html_file" || failures=$((failures + 1))
python3 "$ROOT_DIR/tools/uniopt-json-to-html" --browse-url http://127.0.0.1/browse "$ROOT_DIR/docs/generated/uniopt-demo.schema.json" >"$html_file" || failures=$((failures + 1))
grep -Fq 'http://127.0.0.1/browse' "$html_file" || failures=$((failures + 1))
grep -Fq 'Browse…' "$html_file" || failures=$((failures + 1))
rm -f "$html_file"

python3 "$ROOT_DIR/examples/uniopt-demo/gui" --check >/dev/null || failures=$((failures + 1))
python3 - "$ROOT_DIR/docs/generated/uniopt-demo.schema.json" <<'PY' || failures=$((failures + 1))
import json
import sys

with open(sys.argv[1], encoding="utf-8") as stream:
    schema = json.load(stream)
items = {item["id"]: item for item in schema["items"]}
assert items["runtime.jobs"]["ui"] == {
    "label": "Worker count", "group": "Runtime", "control": "number",
    "placeholder": "", "advanced": False, "order": 10,
    "min": "1", "max": "32", "step": "1", "file_mode": "auto",
}
assert items["greeting.recipient"]["ui"]["label"] == "Recipient"
assert items["interface.help"]["ui"]["control"] == "hidden"
assert items["interface.gui"]["ui"]["control"] == "hidden"
PY

install_root="$(mktemp -d "${TMPDIR:-/tmp}/uniopt-install.XXXXXX")"
PREFIX=/usr/local DESTDIR="$install_root" "$BASH" "$ROOT_DIR/scripts/install-uniopt" >/dev/null || failures=$((failures + 1))
"$install_root/usr/local/bin/uniopt" json "$ROOT_DIR/examples/uniopt-demo/schema.sh" uniopt_demo_schema >/dev/null || failures=$((failures + 1))
[[ -x "$install_root/usr/local/share/uniopt/tools/uniopt-gui" ]] || failures=$((failures + 1))
[[ -r "$install_root/usr/local/share/uniopt/tools/uniopt_gui.py" ]] || failures=$((failures + 1))

demo_install_root="$(mktemp -d "${TMPDIR:-/tmp}/uniopt-demo-install.XXXXXX")"
PREFIX=/usr/local DESTDIR="$demo_install_root" "$BASH" "$ROOT_DIR/examples/uniopt-demo/install" >/dev/null || failures=$((failures + 1))
installed_demo="$demo_install_root/usr/local/bin/uniopt-demo"
installed_completion="$demo_install_root/usr/local/share/bash-completion/completions/uniopt-demo"
[[ "$($installed_demo --style formal Ada)" == 'Greetings, Ada. Sincerely,'* ]] || failures=$((failures + 1))
source "$installed_completion"
COMP_WORDS=(uniopt-demo --style t); COMP_CWORD=2; _uniopt_uniopt_demo
[[ " ${COMPREPLY[*]} " == *' terse '* ]] || failures=$((failures + 1))

if (( failures )); then printf 'documentation/example checks failed: %d\n' "$failures" >&2; exit 1; fi
printf 'Documentation, demo, GUI prototype, and staged installation checks passed\n'

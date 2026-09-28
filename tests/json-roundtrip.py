#!/usr/bin/env python3
"""Behavioral and adversarial tests for Bash -> JSON -> Bash conversion."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[1]
BASH = sys.argv[1] if len(sys.argv) > 1 else "bash"
COMPILER = ROOT / "tools" / "uniopt-json-to-bash"
FIXTURE = ROOT / "tests" / "fixtures" / "roundtrip-schema.sh"
MARKER = Path("/tmp/uniopt-roundtrip-marker")


def run(arguments, **kwargs):
    return subprocess.run(arguments, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, **kwargs)


def export_bash(schema_file, function):
    return run([BASH, str(ROOT / "bin" / "uniopt"), "json", str(schema_file), function]).stdout


def compile_json(json_file, function):
    return run([sys.executable, str(COMPILER), str(json_file), function]).stdout


def reexport(generated_file, function):
    script = 'source "$1"; source "$2"; "$3"; uniopt_json'
    return run([BASH, "-c", script, "roundtrip", str(ROOT / "lib" / "uniopt.sh"), str(generated_file), function]).stdout


with tempfile.TemporaryDirectory(prefix="uniopt-roundtrip-") as temporary:
    temporary = Path(temporary)
    original = export_bash(FIXTURE, "roundtrip_schema")
    schema_file = temporary / "schema.json"
    generated_file = temporary / "generated.sh"
    schema_file.write_bytes(original)
    generated_file.write_bytes(compile_json(schema_file, "generated_roundtrip_schema"))
    run([BASH, "-n", str(generated_file)])
    rebuilt = reexport(generated_file, "generated_roundtrip_schema")
    assert rebuilt == original, "normalized JSON changed after Bash -> JSON -> Bash -> JSON"

    schema = json.loads(original)
    assert schema["bindings"]["bash"]["unknown_destination"] == "ROUNDTRIP_UNKNOWN"
    items = {item["id"]: item for item in schema["items"]}
    assert items["count.positive"]["bindings"]["bash"]["validator"] == "roundtrip_positive"
    assert items["text.dynamic"]["bindings"]["bash"]["default_function"] == "roundtrip_dynamic_default"
    assert items["preset.second"]["sets"] == [
        {"id": "mode.value", "value": "first"},
        {"id": "mode.value", "value": "second"},
    ]

    if MARKER.exists():
        MARKER.unlink()
    behavior = r'''
source "$1"
source "$2"
source "$3"
generated_roundtrip_schema
uniopt_parse --count 2 --second --value '' --value 'two words' --value '*' input --future --other -- --leading '$HOME' $'line one\nline two'
[[ "$COUNT" == 2 && "$MODE" == second && "$DYNAMIC" == 'dynamic value' ]] || exit 10
[[ "$LITERAL" == *'$(touch /tmp/uniopt-roundtrip-marker)'* ]] || exit 11
uniopt_get_all value.repeated
[[ "${#UNIOPT_RESULT[@]}" == 3 && "${UNIOPT_RESULT[0]}" == '' && "${UNIOPT_RESULT[1]}" == 'two words' && "${UNIOPT_RESULT[2]}" == '*' ]] || exit 12
uniopt_get_unknown
[[ "${#UNIOPT_RESULT[@]}" == 2 && "${UNIOPT_RESULT[0]}" == --future && "${UNIOPT_RESULT[1]}" == --other ]] || exit 13
uniopt_get_all command.args
[[ "${#UNIOPT_RESULT[@]}" == 3 && "${UNIOPT_RESULT[0]}" == --leading && "${UNIOPT_RESULT[1]}" == '$HOME' && "${UNIOPT_RESULT[2]}" == $'line one\nline two' ]] || exit 14
if uniopt_parse --count 0 input >/dev/null 2>&1; then exit 15; fi
true
'''
    run([BASH, "-c", behavior, "behavior", str(ROOT / "lib" / "uniopt.sh"), str(FIXTURE), str(generated_file)])
    assert not MARKER.exists(), "generated Bash evaluated schema data"

    for committed in sorted((ROOT / "docs" / "generated").rglob("*.schema.json")):
        function = "roundtrip_" + committed.stem.replace("-", "_").replace(".", "_")
        generated_file.write_bytes(compile_json(committed, function))
        run([BASH, "-n", str(generated_file)])
        assert reexport(generated_file, function) == committed.read_bytes(), str(committed)

    nul_schema = json.loads(original)
    nul_schema["summary"] = "cannot\0represent"
    schema_file.write_text(json.dumps(nul_schema), encoding="utf-8")
    failure = subprocess.run([sys.executable, str(COMPILER), str(schema_file)], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    assert failure.returncode != 0 and b"NUL" in failure.stderr

    duplicate_file = temporary / "duplicate.json"
    duplicate_file.write_text('{"schema_version":1,"schema_version":1}', encoding="utf-8")
    failure = subprocess.run([sys.executable, str(COMPILER), str(duplicate_file)], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    assert failure.returncode != 0 and b"duplicate JSON object key" in failure.stderr

print("Bash/JSON semantic round-trip and adversarial quoting checks passed")

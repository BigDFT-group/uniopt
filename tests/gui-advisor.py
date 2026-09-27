#!/usr/bin/env python3
"""Behavior tests for the backend-neutral GUI advisor model."""

import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from uniopt_gui import AdvisorModel, AdvisorRunner


def load(schema, function, environment=None):
    completed = subprocess.run(
        [str(ROOT / "bin" / "uniopt"), "json", str(schema), function],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=environment,
    )
    return json.loads(completed.stdout)


demo_schema = ROOT / "examples" / "uniopt-demo" / "schema.sh"
demo = load(demo_schema, "uniopt_demo_schema")
model = AdvisorModel(demo)
assert "interface.help" not in model.states and "interface.gui" not in model.states
assert any(not item["ui"]["advanced"] for item in model.items)
assert any(item["ui"]["advanced"] for item in model.items)

values = ["", "two words", "*", "?", "[x]", "$HOME", "a\\b", "λ", "line one\nline two"]
model.set("greeting.recipient", "", True)
model.set("metadata.tag", values, True)
model.set("greeting.extra", ["--leading", "", "tail\nline"], True)
expected = []
for value in values:
    expected.extend(("--tag", value))
expected.extend(("", "--", "--leading", "", "tail\nline"))
assert model.build_args() == expected
display = model.command_display(["uniopt-demo"])
assert "'two words'" in display and "'$HOME'" in display and "'line one\nline two'" in display

runner = AdvisorRunner(
    ROOT / "bin" / "uniopt", demo_schema, "uniopt_demo_schema",
    [ROOT / "examples" / "uniopt-demo" / "uniopt-demo"],
)
assert runner.validate(model.build_args()).returncode == 0
invalid = runner.validate(["--jobs", "zero", "Ada"])
assert invalid.returncode != 0 and "jobs" in invalid.stderr and "unbound variable" not in invalid.stderr

environment = os.environ.copy()
environment["UNIOPT_PREVIEW_COMMAND"] = "wise-up"
preview_schema = ROOT / "examples" / "integration-preview" / "schemas.sh"
wise_up = AdvisorModel(load(preview_schema, "integration_preview_schema", environment))
wise_up.set("launch.check", False, True)
wise_up.set("display.xhost_auth", False, True)
assert wise_up.build_args() == ["--no-check", "--no-xhost-auth"]

environment["UNIOPT_PREVIEW_COMMAND"] = "wise-host-open"
host_open = AdvisorModel(load(preview_schema, "integration_preview_schema", environment))
assert any("Exclusive with" in text for text in host_open.conditions["action.stop"])

environment["UNIOPT_PREVIEW_COMMAND"] = "dockerfile-to-wise-sdk"
converter = AdvisorModel(load(preview_schema, "integration_preview_schema", environment))
assert converter.states["input.dockerfile"].item["ui"]["file_mode"] == "open"
assert converter.states["output.directory"].item["ui"]["file_mode"] == "directory"

print("GUI advisor model and exact argv checks passed")

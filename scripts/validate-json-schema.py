#!/usr/bin/env python3
"""Validate the UniOpt meta-schema and every committed schema instance."""

import json
from pathlib import Path

from jsonschema import Draft202012Validator


ROOT = Path(__file__).resolve().parents[1]
meta_schema = json.loads((ROOT / "schema" / "uniopt.schema.json").read_text(encoding="utf-8"))
Draft202012Validator.check_schema(meta_schema)
validator = Draft202012Validator(meta_schema)

count = 0
for path in sorted((ROOT / "docs" / "generated").rglob("*.schema.json")):
    instance = json.loads(path.read_text(encoding="utf-8"))
    errors = sorted(validator.iter_errors(instance), key=lambda error: list(error.absolute_path))
    if errors:
        details = "\n".join("%s: %s" % ("/".join(map(str, error.absolute_path)), error.message) for error in errors)
        raise SystemExit("%s:\n%s" % (path, details))
    count += 1

print("Validated %d generated schemas against schema/uniopt.schema.json" % count)

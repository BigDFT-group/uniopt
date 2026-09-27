#!/usr/bin/env python3
"""Fail when a repository-local Markdown link points at a missing file."""

import re
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[1]
pattern = re.compile(r"(?<!!)\[[^]]*\]\(([^)]+)\)")
failures = []

for document in sorted(ROOT.rglob("*.md")):
    if ".git" in document.parts:
        continue
    text = document.read_text(encoding="utf-8")
    for match in pattern.finditer(text):
        raw = match.group(1).strip()
        if raw.startswith("<") and raw.endswith(">"):
            raw = raw[1:-1]
        target = unquote(raw.split("#", 1)[0])
        if not target or "://" in target or target.startswith("mailto:"):
            continue
        path = (document.parent / target).resolve()
        if not path.exists():
            line = text.count("\n", 0, match.start()) + 1
            failures.append(f"{document.relative_to(ROOT)}:{line}: missing {target}")

if failures:
    raise SystemExit("\n".join(failures))
print("Repository-local documentation links are valid")

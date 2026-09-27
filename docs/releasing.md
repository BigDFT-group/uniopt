# Release and repository publication

The working tree is prepared as a standalone repository named `uniopt` under
the MIT License. The selected publication target is `BigDFT-group/uniopt` on
GitHub.

## Pre-publication checklist

1. Confirm that the canonical MIT `LICENSE` and copyright holder remain
   correct.
2. Confirm public visibility for `BigDFT-group/uniopt`; the product name is
   UniOpt.
3. Run `./scripts/generate-docs`, `./scripts/generate-llms`, the strict MkDocs
   build, and both supported shell suites.
4. Review `docs/integration-reference-audit.md`; the reference applications
   remain unchanged and several inspected scripts were uncommitted upstream.
5. Create the initial commit on `main`.
6. Create the dedicated remote repository with the chosen visibility, add it as
   `origin`, and push `main`.
7. Enable GitHub Pages with GitHub Actions as its build source and confirm the
   site exposes `/llms.txt` and `/llms-full.txt`.
8. Confirm the Bash, macOS, and documentation jobs pass before creating a
   version tag or release.

An example GitHub publication sequence, after the decisions above, is:

```bash
git add .
git commit -m "Initial standalone UniOpt implementation"
gh repo create BigDFT-group/uniopt --source=. --remote=origin --public
git push -u origin main
gh api repos/BigDFT-group/uniopt/pages -X POST -f build_type=workflow
```

A first semantic version can be chosen from the stability promised for the
public API; the repository does not assume one in advance.

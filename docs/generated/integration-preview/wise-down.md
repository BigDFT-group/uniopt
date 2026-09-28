# `wise-down` GUI preview

This interactive command-line advisor is generated from the same UniOpt schema
used by the preview command. Change fields to see the exact command update
immediately. Basic and advanced options, repeatable values, paths, choices,
tri-state values, positionals, and constraints are presented from schema
metadata.

<iframe
  src="../wise-down.gui.html"
  title="wise-down UniOpt GUI preview"
  style="width: 100%; height: 52rem; border: 1px solid #aeb8c2; border-radius: .4rem; background: white;"
></iframe>

[Open the wise-down advisor in a full browser page](wise-down.gui.html)

!!! note "Static demonstration"

    This hosted advisor builds a command line but does not execute it or browse
    the server filesystem. Install UniOpt and run
    `examples/integration-preview/bin/wise-down --gui` for the complete local
    advisor with **Run** and path browsing.

# UniOpt

UniOpt is a declarative command-line option library for Bash 3.2 and newer.
One schema drives parsing, validation, terminal help, Markdown documentation,
Bash completion, machine-readable JSON, and an optional graphical command-line
advisor while preserving exact argument boundaries.

## Start here

- Follow the [user guide](user-guide.md) to add UniOpt to a Bash program.
- Consult the [public API reference](api-reference.md) for every function and
  declaration attribute.
- Run the [demo](https://github.com/bigdft-group/uniopt/tree/main/examples/uniopt-demo)
  to exercise completion and the GUI advisor.
- Explore the [interactive GUI examples](generated/uniopt-demo.md) to change
  schema-driven controls and watch each command line update in the browser.
- Read [installation and GUI integration](installation-and-gui.md) when
  packaging a command or selecting Qt, Tk, or web presentation.

```bash
./examples/uniopt-demo/uniopt-demo --help
./examples/uniopt-demo/uniopt-demo --gui
```

UniOpt retains Bash semantics. It does not use `eval`, generate parser scripts,
or flatten argument arrays into whitespace-delimited strings.

## Documentation for coding agents

The site root publishes [llms.txt](https://bigdft-group.github.io/uniopt/llms.txt),
a concise project and API map, and
[llms-full.txt](https://bigdft-group.github.io/uniopt/llms-full.txt), a
single-file copy of the complete public documentation. CI regenerates and
compares both files.

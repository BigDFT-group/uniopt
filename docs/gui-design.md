# GUI line-advisor design

Status: implemented prototype contract.

## Product goal

Any program with a side-effect-free UniOpt schema should be able to open an
interactive **line advisor**. The advisor renders the options, shows the exact
argument vector and a copyable shell representation, validates it, and runs the
fixed program when the user selects **Run**.

The GUI is an adapter over the CLI. The CLI remains the authoritative public
interface and the application receives the same argv it would receive from a
terminal. There is no second application API and no conversion of arguments to
a whitespace-delimited command string.

```text
schema ──> controls ──> argv array ──> schema validation ──> fixed executable
             │              │                                  │
             └──── visible line advisor ────────────────────────┘
```

## Recommended entry points

The generic runner is the primary interface:

```text
UNIOPT_GUI_BACKEND=auto \
  uniopt gui SCHEMA_FILE SCHEMA_FUNCTION -- PROGRAM [FIXED_ARG...]
```

Separating `PROGRAM` from the schema is deliberate. JSON describes an
interface; it must not authorize an arbitrary executable. The runner resolves
and fixes the program before showing the window, appends only argv elements
created by the form, and invokes it without a shell.

Every schema receives reserved `-h`/`--help` and `--gui` controls. Applications
handle the selected action immediately after parsing:

```bash
mytool_schema || exit 2
uniopt_parse "$@" || exit 2
if [[ "$UNIOPT_ACTION" == help ]]; then
  uniopt_help
  exit 0
fi
if [[ "$UNIOPT_ACTION" == gui ]]; then
  exec uniopt gui "$SCHEMA_FILE" mytool_schema -- "$0"
fi
```

Required options and positionals do not prevent either built-in action. UniOpt
forbids application declarations from reusing `-h`, `--help`, or `--gui`, so
help, completion, and JSON always describe the same control interface.

## Backend model

The runner supports `auto`, `tk`, `qt`, and `web` behind one model and argv
serializer. Set `UNIOPT_GUI_BACKEND` when an explicit choice is needed.

### Native Tk backend

The Tk frontend uses Python `tkinter` and themed `ttk`
widgets. Tk provides real desktop windows, native file/directory dialogs, no
HTTP listener, and direct subprocess execution. It is a reasonable reference
backend because it commonly ships with Python and works on Linux and macOS.

It is still an optional dependency. Some Linux distributions split Tk into a
separate package, and the current WISE image has Python without `tkinter`.
Running `python3 -m tkinter` is the installation check. A GUI launched inside a
container also needs a working X11/Wayland display path; it does not
automatically become a host-native application.

### Browser backend

The existing HTML renderer remains the portability fallback. It works where Tk
is unavailable and is suitable for remote systems, but command execution needs
a short-lived local backend and, inside WISE, port forwarding. It uses
the same schema model, serializer, validation flow, and fixed executable as the
native backend.

### Qt desktop backend

The Qt for Python frontend provides the same controls and native file dialogs.
It is useful where Qt is already packaged or when a signed application bundle
is wanted, but it brings a substantially larger runtime and requires modern
Python. It remains optional and is never a dependency of the Bash library.

`auto` selects Qt after importing it and confirming a display is available,
then tries Tk, and otherwise starts the browser backend. Detection is silent;
the web server prints
its loopback URL; set `UNIOPT_GUI_OPEN=1` only when the browser shares its
network namespace. Backend selection does not change argv semantics.

## Advisor behavior

The window should contain:

1. a title and command summary;
2. grouped basic and advanced controls;
3. add/remove row editors for repeatable and remainder values;
4. a copyable shell-quoted command line that updates after every edit and is
   labeled as display-only;
5. **Run** and **Close** actions;
6. exit status, stdout, and stderr panes after execution.

The subprocess must run asynchronously so its output does not freeze the
window. Version one may capture output at completion; streaming can follow.
Captured results appear after completion; streaming output and cancellation are
future additions.

Untouched controls are omitted from argv so literal, environment, inherited,
and callback defaults retain their provenance. Required means an argument must
be present; it does not mean a nonempty string. The advisor must therefore
distinguish “not supplied” from “supplied as empty.” Array rows naturally make
that distinction, and scalar controls need an explicit include/reset state.

Tri-state values serialize as omission for `inherit`, the positive spelling
for `true`, and the negative spelling for `false`. Remainder arguments always
follow `--`. Presets emit their alias spelling instead of reproducing their
assignments.

## Validation before execution

The companion command provides a parser-only mode:

```text
uniopt validate SCHEMA_FILE SCHEMA_FUNCTION -- ARG...
```

The advisor runs this automatically when **Run** is selected. There is no
separate validation button. The check covers types, required values, aliases,
constraints, dynamic defaults, environment defaults, and Bash custom
validators without running application domain logic. If it succeeds, the
advisor launches `PROGRAM` with the same argv array. The application parses
again and remains authoritative, which protects callers that bypass the GUI.

A later machine-readable diagnostic format can associate errors with semantic
IDs. The first implementation can display the parser's existing stderr.

## Execution contract

The runner records these values before opening the interface:

- canonical executable path and fixed leading arguments;
- schema file and function;
- working directory, defaulting to the directory where the advisor was
  launched;
- inherited environment, with optional application-controlled additions;
- timeout and output limits supplied by the embedding application or runner.

It never accepts an executable name from schema JSON or a browser request. It
uses an argv subprocess API with shell execution disabled. The shell-quoted
preview is only for human inspection and clipboard use.

Pressing **Run** is the execution authorization. Commands that remove data or
perform another material action may declare a confirmation message; the GUI
shows it immediately before launch. The CLI itself must retain its own safety
checks.

## Presentation metadata

The current `--ui-label`, `--ui-group`, `--ui-control`, `--ui-placeholder`,
`--ui-advanced`, `--ui-order`, `--ui-min`, `--ui-max`, and `--ui-step` hints
cover the initial control layout. Two additions are justified by native
execution:

| Attribute | Scope | Meaning |
|---|---|---|
| `--ui-file-mode auto|open|save|directory` | path option or positional | Choose the native path dialog |
| `--ui-confirm TEXT` | schema | Ask for confirmation before executing this command |

File extensions and MIME filters, conditional visibility, richer descriptions,
and layout columns should wait for concrete application requirements. UI bounds
remain presentation hints; parser types and validators enforce correctness.

The web frontend can browse the filesystem visible to the command runner. Its
picker lists server-side paths through the token-protected loopback endpoint;
it does not use an HTML upload control, because browsers do not reveal a local
absolute path. Inside a container, the picker therefore shows container paths,
which are the paths the launched command can actually use.

## Container and host placement

For host-side WISE launcher commands, run the native advisor on the host and
let it launch the host script. For commands inside WISE, there are three valid
deployments:

1. run Tk inside WISE through its configured display forwarding;
2. run the browser backend inside WISE through an IDE/SSH port forward;
3. run a host advisor connected to a narrowly defined WISE execution bridge.

The third option needs a separate authenticated protocol and is outside the
generic UniOpt runner. A native toolkit alone does not solve container-to-host
execution or display transport.

The standalone prototype implements the shared model, validation command, Tk,
Qt, and web frontends, the demo hook, and integration-preview hooks. Adoption
inside WISE and ContainerXP remains a separate integration step after the
example twins have been exercised.

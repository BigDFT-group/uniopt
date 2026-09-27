# Installation and GUI integration

## Installation strategies

There is no universal package layout for a sourced Bash library. Choose the
model that matches who controls the application and its deployment.

| Strategy | Best for | Trade-off |
|---|---|---|
| Vendor `lib/uniopt.sh` | A script distributed as one repository or archive | Most reproducible; the application owns upgrades and security review |
| Git submodule/subtree | Several actively developed in-house tools | Preserves upstream history but adds repository workflow overhead |
| `make install` prefix | Several local programs sharing one installation | Central upgrade; consumers should locate the installed path explicitly |
| OS/Homebrew package | Organization-wide or public distribution | Best upgrade experience, but needs releases, checksums, packaging metadata, and compatibility policy |

### Vendoring

The recommended first release strategy is to copy a tagged UniOpt
`lib/uniopt.sh` into the application's own `lib/` directory and source it
relative to `BASH_SOURCE`. This keeps the program and parser version coupled and
works without root access or network access at runtime.

### Prefix installation

Install for one user:

```bash
PREFIX="$HOME/.local" ./scripts/install-uniopt
export PATH="$HOME/.local/bin:$PATH"
```

`make install PREFIX="$HOME/.local"` is an equivalent convenience wrapper.

Install system-wide through a package staging root:

```bash
PREFIX=/usr DESTDIR="$package_root" ./scripts/install-uniopt
```

The installed layout is:

```text
PREFIX/bin/uniopt
PREFIX/share/uniopt/lib/uniopt.sh
PREFIX/share/uniopt/docs/
```

`bin/uniopt` discovers both the repository and installed layouts. Set
`UNIOPT_LIB=/custom/path/uniopt.sh` for an explicit override. Applications
should generally source the library using a path they control instead of
depending on a global search.

### Package managers

A future Homebrew formula can install the library under the formula's shared
data directory, the companion command under `bin`, and generated completion
under `bash_completion`. These are standard formula path helpers in the
[Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook). The formula
should depend on no newer Bash because UniOpt targets the macOS system Bash.

For Linux packages, place immutable library data under `/usr/share/uniopt` and
the command under `/usr/bin`, using `DESTDIR` for packaging. Per-user generated
data should follow `$XDG_DATA_HOME` rather than writing into the installation;
the [XDG Base Directory specification](https://specifications.freedesktop.org/basedir/0.8/)
defines the precedence model.

Do not recommend `curl URL | bash` for application startup. Pin a release or
commit and verify its archive in the packaging or vendoring step.

## Converting a UniOpt program into a GUI

UniOpt includes one backend-neutral line advisor with Tk, Qt, and browser
frontends. Every schema reserves `--gui`; the application only needs to route
the resulting built-in action to the generic runner.

The Bash library has no Python dependency. The optional advisor requires
Python 3.8 or newer. The web backend uses only the standard library. The Tk
backend additionally requires `tkinter` (often packaged as `python3-tk` on
Linux). The Qt backend uses the official Qt for Python binding, PySide6:

```bash
python3 -m venv ~/.local/share/uniopt/gui-venv
~/.local/share/uniopt/gui-venv/bin/python -m pip install PySide6
UNIOPT_PYTHON=~/.local/share/uniopt/gui-venv/bin/python \
  UNIOPT_GUI_BACKEND=qt mytool --gui
```

PySide6 is an optional frontend dependency; it is not imported by parsing,
help, completion, Markdown, or JSON generation. On macOS, test Tk with
`python3 -m tkinter`; Python distributions differ in whether Tk is bundled.

The frontend choices deliberately stay small in number:

| Frontend | Additional runtime | Role |
|---|---|---|
| Qt | PySide6 | First desktop choice; polished native widgets and file dialogs |
| Tk | Python `tkinter` module | Smaller native fallback when Qt is absent |
| Web | Python standard library and an existing browser | Dependency-light fallback and remote/container use |

Helpers such as Zenity, YAD, AppleScript dialogs, and platform-specific shell
widgets are not used because they do not provide one consistent dynamic form,
repeatable-row editor, and argv model across Linux and macOS.

UniOpt's JSON output is an interface description. It does not define a remote
execution protocol. A GUI adapter uses two separate phases:

```text
side-effect-free schema file
          │
          ├── uniopt json ──> widgets + client-side constraints
          │
          └── application <argv elements...> ──> normal parser + domain logic
```

The GUI must launch a fixed, trusted application with an argument-vector API
such as Python's `subprocess.run([program, *args], shell=False)`. It must not
concatenate a command string or pass user input to a shell.

The core schema already provides everything needed to make a correct basic
form: semantic IDs, types, choices, defaults, repeatability, required fields,
positionals, remainder arguments, aliases, and constraints. Optional `--ui-*`
attributes improve presentation without changing CLI semantics:

| Attribute | JSON field | Purpose |
|---|---|---|
| `--ui-label TEXT` | `ui.label` | Human-readable field or action label |
| `--ui-group TEXT` | `ui.group` | Section or tab name |
| `--ui-control CONTROL` | `ui.control` | Preferred widget |
| `--ui-placeholder TEXT` | `ui.placeholder` | Empty-field prompt |
| `--ui-advanced` | `ui.advanced` | Put the field in an advanced area |
| `--ui-order INTEGER` | `ui.order` | Stable presentation order |
| `--ui-min VALUE` | `ui.min` | Numeric lower-bound hint |
| `--ui-max VALUE` | `ui.max` | Numeric upper-bound hint |
| `--ui-step VALUE` | `ui.step` | Numeric increment hint |
| `--ui-file-mode MODE` | `ui.file_mode` | `auto`, `open`, `save`, or `directory` chooser |

At schema level, `--ui-confirm TEXT` requests confirmation immediately before
execution. Native frontends show a dialog and the browser frontend uses a
confirmation prompt.

Controls are `auto`, `text`, `textarea`, `password`, `number`, `select`,
`radio`, `checkbox`, `tristate`, `file`, `directory`, `list`, and `hidden`.
They are advisory. Native frontends use platform file dialogs. The executable
web advisor provides a server-side path picker for the filesystem in which the
command will run. A static generated form has text fields only because an HTML
upload control does not reveal a usable absolute CLI path.

Suggested widget mapping:

| Schema item | GUI control |
|---|---|
| `string`, `int`, `uint` | Text or numeric input |
| `path` | Text input plus native file/directory chooser |
| `enum` + `choices` | Select or radio group |
| `boolean` | Checkbox; offer explicit false when `negative_long` exists |
| `tristate` | Inherit / enabled / disabled selector |
| `repeatable` | Add/remove list with one argument per row |
| positional | Ordered required/optional field |
| remainder | Ordered argument list editor |
| alias with `sets` | Preset button or checkbox |
| constraints | Form validation and contextual explanation |

Use the semantic `id` as the widget and persistence key. Treat CLI spellings as
launch serialization details. This lets a future release rename `--colour` to
`--color` without invalidating saved GUI state.

### Form behavior

A GUI should follow these rules to preserve the command's behavior:

- Leave untouched fields out of the generated argv. This allows literal,
  environment, inherited, and callback defaults to keep their CLI provenance.
- Serialize each repeatable value as a separate option and value pair. Use a
  row editor rather than splitting a string on whitespace.
- Serialize positionals in declaration order. Put a literal `--` before the
  first remainder value so leading hyphens remain data.
- Preserve empty strings and embedded newlines as individual values when the
  CLI supports them. The demo uses one textarea row per array element.
- Map tri-state values to omission for `inherit`, the positive spelling for
  `true`, and the negative spelling for `false`.
- Treat an alias as one action spelling. Do not duplicate its `sets` values in
  argv; the parser applies those assignments and records their provenance.
- Show constraints early for convenience, then run the real parser and display
  its diagnostics. Core validation and custom validators remain authoritative.
- Keep passwords out of previews, logs, browser storage, and process listings
  when the application handles secrets. A password widget only masks display;
  it does not make command-line arguments secret.

Static defaults can initialize controls. `dynamic_default` and
`environment_default` deliberately expose their source rather than executing
it during introspection. A production GUI has three choices:

1. show those controls as “resolved when run”;
2. add an application-specific, side-effect-free resolved-default endpoint;
3. leave them unset and let normal parsing resolve them at launch.

Custom validator function names are Bash implementation details. A generic GUI
can run normal CLI validation after submission, or an application can publish
additional portable constraints. Do not attempt to execute validator names in
the GUI process.

Presentation bounds do not add parser validation. If `--ui-min 1` is important
to correctness, also declare a type or custom validator that enforces it. This
ensures terminal, GUI, and automated callers receive the same result.

## Run the demo GUI

From the repository root:

```bash
./examples/uniopt-demo/uniopt-demo --gui
```

On a desktop, `auto` silently uses Qt when available, then Tk. If neither native
backend can open a display, it starts a loopback web server and prints its URL.
No GUI toolkit is installed or required by the core package. Force a
frontend when testing:

```bash
UNIOPT_GUI_BACKEND=tk ./examples/uniopt-demo/uniopt-demo --gui
UNIOPT_GUI_BACKEND=qt ./examples/uniopt-demo/uniopt-demo --gui
UNIOPT_GUI_BACKEND=web UNIOPT_GUI_OPEN=1 \
  ./examples/uniopt-demo/uniopt-demo --gui
```

Python 3 is required for the advisor. Tk is commonly packaged as `python3-tk`.
The Qt backend uses PySide6 and is optional. Tk uses Python's optional
`tkinter` module. The browser backend uses only the Python standard library and
is the smallest guaranteed fallback.

### Running inside WISE or another container

Container loopback is separate from host loopback. `--open` cannot make an
unforwarded container port reachable from the host browser. Start the GUI on a
known port instead:

```bash
UNIOPT_GUI_BACKEND=web UNIOPT_GUI_PORT=8765 \
  ./examples/uniopt-demo/uniopt-demo --gui
```

Then forward container port `8765` in WISE's **Ports** view and select **Open in
Browser** for the forwarded address. The server provides the form at `/`, and
the form posts to a same-origin relative path. It therefore works if the host
side uses a different port. Keep the GUI process running while using the page.

The same rule applies to SSH and other container environments: establish a
loopback tunnel or IDE port forward first, then visit its host-side URL. The
demo deliberately binds only container loopback; it does not expose an
unauthenticated development runner on every container interface.

The command line preview updates immediately whenever a control changes. The
only execution button is **Run**. Run first invokes the schema parser in
validation-only mode; parser diagnostics are shown instead of launching the
program when validation fails.

The server uses an unguessable URL for the current run, accepts JSON only, and
can invoke only the executable fixed by the launcher. It passes arguments as
an array with `shell=False` and displays stdout, stderr, and exit status. A
deployed web application still needs its normal authentication, authorization,
input-size, working-directory, environment, and resource policies.

The web path picker browses the command runner's filesystem. In WISE this means
container paths, even when the page is displayed by a host browser. This is
intentional: a host path that is not mounted in the container cannot be passed
meaningfully to the container command.

The demo schema shows presentation hints directly:

```bash
uniopt_option runtime.jobs \
  --short -j --long --jobs --dest JOBS --type uint --default 1 \
  --validator uniopt_demo_positive --metavar N \
  --help "Positive worker count" \
  --ui-label "Worker count" --ui-group Runtime --ui-control number \
  --ui-order 10 --ui-min 1 --ui-max 32 --ui-step 1
```

`uniopt_demo_positive` remains the real validation. The other attributes tell
the GUI how to present the same option.

## Generate a static form

The repository includes a small dependency-free converter:

```bash
scripts/generate-docs
tools/uniopt-json-to-html docs/generated/uniopt-demo.schema.json >demo.html
```

It renders the same grouped form and previews the exact argument vector but has
no Run button. The generated page has no external dependencies. To connect it
to an application service, supply a JSON POST endpoint that accepts
`{"args":[...]}`:

```bash
tools/uniopt-json-to-html \
  --submit-url http://127.0.0.1:8080/run \
  docs/generated/uniopt-demo.schema.json >demo.html
```

The endpoint option only changes the page; the converter does not create or
secure a server. The demo runner is the reference for the expected response:
`{"status": 0, "stdout": "...", "stderr": "..."}`.

## Choosing an application architecture

For a local desktop tool, generate widgets from JSON and invoke the CLI as a
child process. This naturally preserves local paths and the user's environment.
For a hosted web GUI, treat the CLI as a backend job: define which executable
and working directory are allowed, translate uploaded files to controlled
server paths, isolate jobs, stream or capture output, and return parser errors
to the corresponding semantic IDs. A static form alone must never be allowed
to choose an arbitrary executable.

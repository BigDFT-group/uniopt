# `uniopt-demo`

Build a greeting while demonstrating UniOpt's schema-driven interfaces.

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `-h, --help` | `boolean` | `false` | Show help and exit |
| `--gui` | `boolean` | `false` | Open the graphical command-line advisor |
| `-n, --name NAME` | `string` | `dynamic: uniopt_demo_default_name` | Name of the sender |
| `-s, --style STYLE` | `enum` | `friendly` | Greeting style |
| `-o, --output PATH` | `path` | `-` | Write to PATH instead of standard output |
| `--loud` | `boolean` | `false` | Use uppercase output |
| `--color, --no-color` | `tristate` | `inherit` | Enable, disable, or inherit terminal color |
| `-j, --jobs N` | `uint` | `1` | Positive worker count |
| `-t, --tag TAG` | `string` | `` | Attach a tag; may be repeated |
| `--show-sources` | `boolean` | `false` | Print selected value provenance |
| `--quick` | `action` | `` | Alias for terse, uppercase output |

## Arguments

| Argument | Type | Required | Description |
|---|---|---|---|
| `RECIPIENT` | `string` | yes | Person or group to greet |
| `WORD...` | `string` | no | Extra words preserved after -- |

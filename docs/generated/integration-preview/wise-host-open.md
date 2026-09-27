# `wise-host-open`

Run or contact the WISE host opener bridge

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `-h, --help` | `boolean` | `false` | Show help and exit |
| `--gui` | `boolean` | `false` | Open the graphical command-line advisor |
| `--env-file PATH` | `path` | `` | Env file to use |
| `--name NAME` | `string` | `` | Select a named WISE session |
| `--socket PATH` | `path` | `` | Override the host-open socket path |
| `--open-command CMD` | `string` | `` | Host opener command |
| `--once` | `boolean` | `false` | Serve one request and exit |
| `--test-mode` | `boolean` | `false` | Print accepted targets instead of opening |
| `--daemon` | `boolean` | `false` | Start a managed bridge |
| `--stop` | `boolean` | `false` | Stop the managed bridge |
| `--client URL` | `string` | `` | Send a URL to the bridge |
| `--client-file PATH` | `path` | `` | Send a PDF or DOCX path |

## Constraints

- `mutex`: `action.daemon` `action.stop` `action.client` `action.client_file`

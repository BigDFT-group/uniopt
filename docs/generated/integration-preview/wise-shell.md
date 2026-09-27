# `wise-shell`

Run a command in the WISE container

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `-h, --help` | `boolean` | `false` | Show help and exit |
| `--gui` | `boolean` | `false` | Open the graphical command-line advisor |
| `--env-file PATH` | `path` | `` | Env file to use |
| `--name NAME` | `string` | `` | Select a named WISE session |
| `--extra-compose PATH` | `path` | `` | Add an extra Docker Compose file |

## Arguments

| Argument | Type | Required | Description |
|---|---|---|---|
| `COMMAND...` | `string` | no | Command and exact arguments |

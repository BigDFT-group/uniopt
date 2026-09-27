# `dockerfile-to-wise-sdk`

Convert a Dockerfile into WISE runtime installation files

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `-h, --help` | `boolean` | `false` | Show help and exit |
| `--gui` | `boolean` | `false` | Open the graphical command-line advisor |
| `--output-dir PATH` | `path` | `` | Directory for generated files |
| `--script-name NAME` | `string` | `install-sdk.sh` | Generated installer filename |
| `--env-name NAME` | `string` | `wise.extra.env` | Generated environment filename |
| `--warnings-name NAME` | `string` | `conversion-warnings.txt` | Generated warnings filename |

## Arguments

| Argument | Type | Required | Description |
|---|---|---|---|
| `DOCKERFILE` | `path` | yes | Input Dockerfile |

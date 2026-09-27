# `wise-up`

Launch a WISE session

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `-h, --help` | `boolean` | `false` | Show help and exit |
| `--gui` | `boolean` | `false` | Open the graphical command-line advisor |
| `--env-file PATH` | `path` | `` | Env file to use |
| `--name NAME` | `string` | `` | Select a named WISE session |
| `--extra-compose PATH` | `path` | `` | Add an extra Docker Compose file |
| `--build` | `boolean` | `false` | Rebuild the image before launch |
| `--replace` | `boolean` | `false` | Allow replacing an existing WISE container |
| `--no-check` | `boolean` | `true` | Skip wise-check before launch |
| `--host-open` | `boolean` | `false` | Start the host opener bridge |
| `--no-xhost-auth` | `boolean` | `true` | Skip xhost authorization |

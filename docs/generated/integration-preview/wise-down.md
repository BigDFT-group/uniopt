# `wise-down`

Stop a WISE session

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `-h, --help` | `boolean` | `false` | Show help and exit |
| `--gui` | `boolean` | `false` | Open the graphical command-line advisor |
| `--env-file PATH` | `path` | `` | Env file to use |
| `--name NAME` | `string` | `` | Select a named WISE session |
| `--extra-compose PATH` | `path` | `` | Add an extra Docker Compose file |
| `--prune-inner-containers` | `boolean` | `false` | Prune inner images, networks, and build cache |
| `--prune-inner-container-volumes` | `action` | `` | Also prune inner Docker volumes |
| `--remove-inner-container-volume` | `boolean` | `false` | Remove the shared sidecar data volume |

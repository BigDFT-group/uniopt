# `laramk`

Build a LARA SDK container command

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `-h, --help` | `boolean` | `false` | Show help and exit |
| `--gui` | `boolean` | `false` | Open the graphical command-line advisor |
| `-X, --display` | `boolean` | `false` | Enable host display usage |
| `-w, --workdir` | `boolean` | `false` | Mount the present directory |
| `-k, --keep` | `boolean` | `false` | Keep the container after it exits |
| `-r, --root` | `boolean` | `false` | Run as root |
| `-x, --extra-cmd ARG` | `string` | `` | Additional docker run argument |
| `-e, --extra-positional ARG` | `string` | `` | Additional command argument |
| `-d, --homedir PATH` | `path` | `/tmp/fake_home` | Container home directory |
| `-g, --gpus` | `boolean` | `false` | Enable NVIDIA GPU access |
| `-s, --sources PATH` | `path` | `dynamic: preview_bigdft_sources` | BigDFT source directory |
| `-b, --binaries PATH` | `path` | `dynamic: preview_bigdft_binaries` | Binaries directory |
| `-l, --lara-sources PATH` | `path` | `dynamic: preview_lara_sources` | LARA source directory; migration spelling for the duplicated legacy --sources |
| `-i, --image IMAGE` | `string` | `lara/sdk:latest` | SDK container image |
| `-o, --ontoflow PATH` | `path` | `dynamic: preview_ontoflow_sources` | Ontoflow source directory |
| `-a, --apikeysdir PATH` | `path` | `dynamic: preview_lara_keys` | API key directory |
| `-p, --port PORT` | `uint` | `` | Host port mapped to container port 8888 |

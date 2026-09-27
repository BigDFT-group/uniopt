# `bigdftmk`

Build a BigDFT SDK container command

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
| `-i, --image IMAGE` | `string` | `bigdft/sdk:latest` | SDK container image |
| `-b, --binaries PATH` | `path` | `dynamic: preview_bigdft_binaries` | Binaries directory |
| `-t, --target PATH` | `path` | `/opt/bigdft` | Target binaries directory |
| `-p, --port PORT` | `uint` | `` | Host port mapped to container port 8888 |

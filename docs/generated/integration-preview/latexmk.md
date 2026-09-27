# `latexmk`

Build a LaTeX container command

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
| `-s, --sources PATH` | `path` | `` | Source LaTeX file |
| `--extradir PATH` | `path` | `` | Additional mounted directory; legacy -x is shadowed by --extra-cmd |
| `-o, --outputdir PATH` | `path` | `/tmp` | Output directory relative to the source |
| `-i, --image IMAGE` | `string` | `bigdft/latex` | LaTeX container image |

# `wise-env`

Generate a WISE session environment

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `-h, --help` | `boolean` | `false` | Show help and exit |
| `--gui` | `boolean` | `false` | Open the graphical command-line advisor |
| `--env-file PATH` | `path` | `` | Env file to use |
| `--name NAME` | `string` | `` | Select a named WISE session |
| `--base-env PATH` | `path` | `` | Base env file to read |
| `--workdir PATH` | `path` | `` | Host workdir mounted into the container |
| `--workspace-path PATH` | `path` | `` | Absolute workspace path inside the container |
| `--platform NAME` | `enum` | `` | Platform override |
| `--gpu` | `boolean` | `false` | Enable the GPU Compose configuration |
| `--container-mode MODE` | `enum` | `` | Container engine mode |
| `--inner-containers` | `action` | `` | Alias for --container-mode sidecar |
| `--docker-data-volume NAME` | `string` | `` | Shared sidecar Docker data volume |
| `--sidecar-network MODE` | `enum` | `` | Sidecar outer network mode |
| `--network-subnet CIDR` | `string` | `` | Explicit Docker bridge IPv4 subnet |
| `--network-ipv6-subnet CIDR` | `string` | `` | Explicit Docker bridge IPv6 subnet |
| `--no-ipv6` | `boolean` | `false` | Disable IPv6 for the sidecar bridge |
| `--openvscode-port PORT` | `uint` | `` | OpenVSCode publication port |
| `--publish SPEC` | `string` | `` | Publish an additional sidecar port |
| `--hostname NAME` | `string` | `` | Container hostname and Compose project name |
| `--session-home PATH` | `path` | `` | Host directory mounted as CONTAINER_HOME |
| `--host-tmp PATH` | `path` | `` | Host directory mounted as container /tmp |
| `--host-gitconfig, --no-host-gitconfig` | `tristate` | `inherit` | Enable, disable, or inherit host Git configuration |
| `--startup-script PATH` | `path` | `` | Container startup script |
| `--xhost-localuser` | `boolean` | `false` | Authorize local X11 access |
| `--host-open, --no-host-open` | `tristate` | `inherit` | Enable, disable, or inherit the host opener bridge |

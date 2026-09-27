#!/usr/bin/env bash
# Side-effect-free UniOpt schemas modeled from the public WISE and ContainerXP CLIs.

PREVIEW_IDS=()
PREVIEW_MULTI_IDS=()
PREVIEW_HAS_UNKNOWN=0
PREVIEW_SHORT_HELP=0

preview_reset() {
  uniopt_reset
  PREVIEW_IDS=()
  PREVIEW_MULTI_IDS=()
  PREVIEW_HAS_UNKNOWN=0
  PREVIEW_SHORT_HELP=0
}

preview_option() {
  PREVIEW_IDS[${#PREVIEW_IDS[@]}]="$1"
  uniopt_option "$@"
}

preview_multi_option() {
  PREVIEW_IDS[${#PREVIEW_IDS[@]}]="$1"
  PREVIEW_MULTI_IDS[${#PREVIEW_MULTI_IDS[@]}]="$1"
  uniopt_option "$@" --repeatable
}

preview_positional() {
  PREVIEW_IDS[${#PREVIEW_IDS[@]}]="$1"
  uniopt_positional "$@"
}

preview_remainder() {
  PREVIEW_IDS[${#PREVIEW_IDS[@]}]="$1"
  PREVIEW_MULTI_IDS[${#PREVIEW_MULTI_IDS[@]}]="$1"
  uniopt_positional "$@" --remainder
}

preview_help_option() { :; }

preview_wise_session() {
  preview_option session.env_file --long --env-file --dest ENV_FILE --type path \
    --metavar PATH --help "Env file to use" --ui-group Session --ui-label "Environment file" --ui-order 20
  preview_option session.name --long --name --dest OV_NAME --metavar NAME \
    --help "Select a named WISE session" --ui-group Session --ui-label "Session name" --ui-order 10
}

preview_wise_compose() {
  preview_multi_option compose.extra --long --extra-compose --dest EXTRA_COMPOSE --type path \
    --metavar PATH --help "Add an extra Docker Compose file" --ui-group Compose --ui-control list --ui-order 10
}

preview_schema_wise_env() {
  preview_reset; uniopt_schema wise-env --summary "Generate a WISE session environment" --unknown error
  preview_wise_session
  preview_option session.base_env --long --base-env --dest BASE_ENV --type path --metavar PATH --help "Base env file to read" --ui-group Session --ui-order 30
  preview_option workspace.host --long --workdir --dest HOST_WORKDIR --type path --metavar PATH --help "Host workdir mounted into the container" --ui-group Workspace --ui-order 10
  preview_option workspace.container --long --workspace-path --dest WORKSPACE_PATH --type path --metavar PATH --help "Absolute workspace path inside the container" --ui-group Workspace --ui-order 20
  preview_option platform.name --long --platform --dest PLATFORM --type enum --choice auto --choice linux --choice wsl --metavar NAME --help "Platform override" --ui-group Runtime --ui-order 10
  preview_option gpu.enabled --long --gpu --dest GPU --type boolean --default false --help "Enable the GPU Compose configuration" --ui-group Runtime --ui-order 20
  preview_option container.mode --long --container-mode --dest CONTAINER_MODE --type enum --choice none --choice sidecar --metavar MODE --help "Container engine mode" --ui-group Containers --ui-order 10
  uniopt_alias container.inner --long --inner-containers --set container.mode sidecar --help "Alias for --container-mode sidecar" --ui-group Containers --ui-label "Enable inner containers" --ui-order 20
  preview_option container.data_volume --long --docker-data-volume --dest DATA_VOLUME --metavar NAME --help "Shared sidecar Docker data volume" --ui-group Containers --ui-order 30
  preview_option network.sidecar_mode --long --sidecar-network --dest SIDECAR_NETWORK --type enum --choice bridge --choice host --metavar MODE --help "Sidecar outer network mode" --ui-group Network --ui-order 10
  preview_option network.ipv4_subnet --long --network-subnet --dest NETWORK_SUBNET --metavar CIDR --help "Explicit Docker bridge IPv4 subnet" --ui-group Network --ui-order 20
  preview_option network.ipv6_subnet --long --network-ipv6-subnet --dest IPV6_SUBNET --metavar CIDR --help "Explicit Docker bridge IPv6 subnet" --ui-group Network --ui-order 30
  preview_option network.no_ipv6 --long --no-ipv6 --dest NO_IPV6 --type boolean --default false --help "Disable IPv6 for the sidecar bridge" --ui-group Network --ui-order 40
  preview_option network.openvscode_port --long --openvscode-port --dest OPENVSCODE_PORT --type uint --metavar PORT --help "OpenVSCode publication port" --ui-group Network --ui-control number --ui-min 1 --ui-max 65535 --ui-order 50
  preview_multi_option network.publish --long --publish --dest PUBLISH --metavar SPEC --help "Publish an additional sidecar port" --ui-group Network --ui-control list --ui-order 60
  preview_option container.hostname --long --hostname --dest HOSTNAME_OVERRIDE --metavar NAME --help "Container hostname and Compose project name" --ui-group Containers --ui-order 40
  preview_option workspace.session_home --long --session-home --dest SESSION_HOME --type path --metavar PATH --help "Host directory mounted as CONTAINER_HOME" --ui-group Workspace --ui-order 30
  preview_option workspace.host_tmp --long --host-tmp --dest HOST_TMP --type path --metavar PATH --help "Host directory mounted as container /tmp" --ui-group Workspace --ui-order 40
  preview_option git.mode --long --host-gitconfig --neg-long --no-host-gitconfig --dest HOST_GITCONFIG --type tristate --default inherit --help "Enable, disable, or inherit host Git configuration" --ui-group Integration --ui-order 10
  preview_option startup.script --long --startup-script --dest STARTUP_SCRIPT --type path --metavar PATH --help "Container startup script" --ui-group Integration --ui-order 20
  preview_option display.xhost --long --xhost-localuser --dest XHOST_LOCALUSER --type boolean --default false --help "Authorize local X11 access" --ui-group Integration --ui-order 30
  preview_option host.open --long --host-open --neg-long --no-host-open --dest HOST_OPEN --type tristate --default inherit --help "Enable, disable, or inherit the host opener bridge" --ui-group Integration --ui-order 40
  preview_help_option
}

preview_schema_wise_up() {
  preview_reset; uniopt_schema wise-up --summary "Launch a WISE session" --unknown collect --unknown-dest COMPOSE_ARGS; PREVIEW_HAS_UNKNOWN=1
  preview_wise_session; preview_wise_compose
  preview_option launch.build --long --build --dest DO_BUILD --type boolean --default false --help "Rebuild the image before launch" --ui-group Launch --ui-order 10
  preview_option launch.replace --long --replace --dest DO_REPLACE --type boolean --default false --help "Allow replacing an existing WISE container" --ui-group Launch --ui-order 20
  preview_option launch.check --long --no-check --dest DO_CHECK --type boolean --default true --store-const false --help "Skip wise-check before launch" --ui-group Launch --ui-label "Run preflight check" --ui-order 30
  preview_option host.open --long --host-open --dest HOST_OPEN --type boolean --default false --help "Start the host opener bridge" --ui-group Integration --ui-order 10
  preview_option display.xhost_auth --long --no-xhost-auth --dest XHOST_AUTH --type boolean --default true --store-const false --help "Skip xhost authorization" --ui-group Integration --ui-label "Run xhost authorization" --ui-order 20
  preview_help_option
}

preview_schema_wise_down() {
  preview_reset; uniopt_schema wise-down --summary "Stop a WISE session" --unknown error --ui-confirm "Stop this WISE session and perform the selected cleanup actions?"
  preview_wise_session; preview_wise_compose
  preview_option prune.inner --long --prune-inner-containers --dest PRUNE_INNER --type boolean --default false --help "Prune inner images, networks, and build cache" --ui-group Cleanup --ui-order 10
  preview_option prune.volumes --dest PRUNE_VOLUMES --type boolean --default false --internal
  uniopt_alias prune.inner_volumes --long --prune-inner-container-volumes --set prune.inner true --set prune.volumes true --help "Also prune inner Docker volumes" --ui-group Cleanup --ui-order 20
  preview_option prune.data_volume --long --remove-inner-container-volume --dest REMOVE_DATA_VOLUME --type boolean --default false --help "Remove the shared sidecar data volume" --ui-group Cleanup --ui-order 30
  preview_help_option
}

preview_schema_wise_shell() {
  preview_reset; uniopt_schema wise-shell --summary "Run a command in the WISE container" --unknown error
  preview_wise_session; preview_wise_compose; preview_help_option
  preview_remainder shell.command --dest SHELL_ARGS --metavar COMMAND --help "Command and exact arguments" --ui-group Command --ui-label "Command arguments" --ui-control list
}

preview_schema_wise_host_open() {
  preview_reset; uniopt_schema wise-host-open --summary "Run or contact the WISE host opener bridge" --unknown error
  preview_wise_session
  preview_option bridge.socket --long --socket --dest SOCKET_PATH --type path --metavar PATH --help "Override the host-open socket path" --ui-group Bridge --ui-order 10
  preview_option bridge.open_command --long --open-command --dest OPEN_COMMAND --metavar CMD --help "Host opener command" --ui-group Bridge --ui-order 20
  preview_option bridge.once --long --once --dest ONCE --type boolean --default false --help "Serve one request and exit" --ui-group Bridge --ui-order 30
  preview_option bridge.test_mode --long --test-mode --dest TEST_MODE --type boolean --default false --help "Print accepted targets instead of opening" --ui-group Bridge --ui-order 40
  preview_option action.daemon --long --daemon --dest DAEMON --type boolean --default false --help "Start a managed bridge" --ui-group Action --ui-order 10
  preview_option action.stop --long --stop --dest STOP --type boolean --default false --help "Stop the managed bridge" --ui-group Action --ui-order 20
  preview_option action.client --long --client --dest CLIENT_URL --metavar URL --help "Send a URL to the bridge" --ui-group Action --ui-order 30
  preview_option action.client_file --long --client-file --dest CLIENT_FILE --type path --metavar PATH --help "Send a PDF or DOCX path" --ui-group Action --ui-order 40
  uniopt_constraint mutex action.daemon action.stop action.client action.client_file
  preview_help_option
}

preview_schema_dockerfile_to_wise_sdk() {
  preview_reset; uniopt_schema dockerfile-to-wise-sdk --summary "Convert a Dockerfile into WISE runtime installation files" --unknown error
  preview_option output.directory --long --output-dir --dest OUTPUT_DIR --type path --required --metavar PATH --help "Directory for generated files" --ui-group Output --ui-control directory --ui-file-mode directory --ui-order 10
  preview_option output.script_name --long --script-name --dest SCRIPT_NAME --default install-sdk.sh --metavar NAME --help "Generated installer filename" --ui-group Output --ui-order 20
  preview_option output.env_name --long --env-name --dest ENV_NAME --default wise.extra.env --metavar NAME --help "Generated environment filename" --ui-group Output --ui-order 30
  preview_option output.warnings_name --long --warnings-name --dest WARNINGS_NAME --default conversion-warnings.txt --metavar NAME --help "Generated warnings filename" --ui-group Output --ui-order 40
  preview_help_option
  preview_positional input.dockerfile --dest DOCKERFILE --type path --required --metavar DOCKERFILE --help "Input Dockerfile" --ui-group Input --ui-control file --ui-file-mode open --ui-order 10
}

preview_container_env_default() { local name="$2"; printf -v "$1" '%s' "${!name-}"; }
preview_bigdft_sources() { preview_container_env_default "$1" BIGDFT_SUITE_SOURCES; }
preview_bigdft_binaries() { preview_container_env_default "$1" BIGDFT_SUITE_BINARIES; }
preview_lara_sources() { preview_container_env_default "$1" LARA_SOURCES; }
preview_ontoflow_sources() { preview_container_env_default "$1" ONTOFLOW_SOURCES; }
preview_lara_keys() { printf -v "$1" '%s' "${HOME:-/tmp}/.lara"; }

preview_container_base() {
  preview_option container.display --short -X --long --display --dest WITH_DISPLAY --type boolean --default false --help "Enable host display usage" --ui-group Container --ui-order 10
  preview_option container.workdir --short -w --long --workdir --dest WITH_WORKDIR --type boolean --default false --help "Mount the present directory" --ui-group Container --ui-order 20
  preview_option container.keep --short -k --long --keep --dest KEEP --type boolean --default false --help "Keep the container after it exits" --ui-group Container --ui-order 30
  preview_option container.root --short -r --long --root --dest EMPLOY_ROOT_USER --type boolean --default false --help "Run as root" --ui-group Container --ui-order 40
  preview_option container.extra_commands --short -x --long --extra-cmd --dest EXTRA_COMMANDS --metavar ARG --help "Additional docker run argument" --ui-group Advanced --ui-advanced --ui-order 10
  preview_option command.extra_positional --short -e --long --extra-positional --dest EXTRA_POSITIONAL --metavar ARG --help "Additional command argument" --ui-group Command --ui-advanced --ui-order 10
  preview_option container.home --short -d --long --homedir --dest HOMEDIR --type path --default /tmp/fake_home --metavar PATH --help "Container home directory" --ui-group Container --ui-order 50
  preview_option container.gpu --short -g --long --gpus --dest USE_GPU --type boolean --default false --help "Enable NVIDIA GPU access" --ui-group Container --ui-order 60
}

preview_container_help() {
  PREVIEW_SHORT_HELP=1
}

preview_schema_bigdftmk() {
  preview_reset; uniopt_schema bigdftmk --summary "Build a BigDFT SDK container command" --unknown collect --unknown-dest POSITIONAL; PREVIEW_HAS_UNKNOWN=1
  preview_container_base
  preview_option source.bigdft --short -s --long --sources --dest SOURCEDIR --type path --default-fn preview_bigdft_sources --metavar PATH --help "BigDFT source directory" --ui-group BigDFT --ui-order 10
  preview_option container.image --short -i --long --image --dest CONTAINER --default bigdft/sdk:latest --metavar IMAGE --help "SDK container image" --ui-group BigDFT --ui-order 20
  preview_option output.binaries --short -b --long --binaries --dest BINARIES --type path --default-fn preview_bigdft_binaries --metavar PATH --help "Binaries directory" --ui-group BigDFT --ui-order 30
  preview_option output.target --short -t --long --target --dest TARGET --type path --default /opt/bigdft --metavar PATH --help "Target binaries directory" --ui-group BigDFT --ui-order 40
  preview_option network.port --short -p --long --port --dest PORT --type uint --metavar PORT --help "Host port mapped to container port 8888" --ui-group Network --ui-control number --ui-min 1 --ui-max 65535
  preview_container_help
}

preview_schema_laramk() {
  preview_reset; uniopt_schema laramk --summary "Build a LARA SDK container command" --unknown collect --unknown-dest POSITIONAL; PREVIEW_HAS_UNKNOWN=1
  preview_container_base
  preview_option source.bigdft --short -s --long --sources --dest SOURCEDIR --type path --default-fn preview_bigdft_sources --metavar PATH --help "BigDFT source directory" --ui-group Sources --ui-order 10
  preview_option output.binaries --short -b --long --binaries --dest BINARIES --type path --default-fn preview_bigdft_binaries --metavar PATH --help "Binaries directory" --ui-group Output --ui-order 10
  preview_option source.lara --short -l --long --lara-sources --dest LARA_SOURCE --type path --default-fn preview_lara_sources --metavar PATH --help "LARA source directory; migration spelling for the duplicated legacy --sources" --ui-group Sources --ui-order 20
  preview_option container.image --short -i --long --image --dest CONTAINER --default lara/sdk:latest --metavar IMAGE --help "SDK container image" --ui-group Container --ui-order 70
  preview_option source.ontoflow --short -o --long --ontoflow --dest ONTOFLOW_SOURCE --type path --default-fn preview_ontoflow_sources --metavar PATH --help "Ontoflow source directory" --ui-group Sources --ui-order 30
  preview_option auth.keys --short -a --long --apikeysdir --dest KEYS_DIR --type path --default-fn preview_lara_keys --metavar PATH --help "API key directory" --ui-group Sources --ui-control directory --ui-order 40
  preview_option network.port --short -p --long --port --dest PORT --type uint --metavar PORT --help "Host port mapped to container port 8888" --ui-group Network --ui-control number --ui-min 1 --ui-max 65535
  preview_container_help
}

preview_schema_latexmk() {
  preview_reset; uniopt_schema latexmk --summary "Build a LaTeX container command" --unknown collect --unknown-dest POSITIONAL; PREVIEW_HAS_UNKNOWN=1
  preview_container_base
  preview_option input.source --short -s --long --sources --dest SOURCE_FILE --type path --metavar PATH --help "Source LaTeX file" --ui-group LaTeX --ui-control file --ui-order 10
  preview_option input.extra_dir --long --extradir --dest EXTRA_DIR --type path --metavar PATH --help "Additional mounted directory; legacy -x is shadowed by --extra-cmd" --ui-group LaTeX --ui-control directory --ui-order 20
  preview_option output.directory --short -o --long --outputdir --dest OUTPUT_DIRECTORY --type path --default /tmp --metavar PATH --help "Output directory relative to the source" --ui-group LaTeX --ui-order 30
  preview_option container.image --short -i --long --image --dest CONTAINER --default bigdft/latex --metavar IMAGE --help "LaTeX container image" --ui-group Container --ui-order 70
  preview_container_help
}

integration_preview_schema() {
  case "${UNIOPT_PREVIEW_COMMAND-}" in
    wise-env) preview_schema_wise_env ;;
    wise-up) preview_schema_wise_up ;;
    wise-down) preview_schema_wise_down ;;
    wise-shell) preview_schema_wise_shell ;;
    wise-host-open) preview_schema_wise_host_open ;;
    dockerfile-to-wise-sdk) preview_schema_dockerfile_to_wise_sdk ;;
    bigdftmk) preview_schema_bigdftmk ;;
    laramk) preview_schema_laramk ;;
    latexmk) preview_schema_latexmk ;;
    *) printf 'unknown integration preview command: %s\n' "${UNIOPT_PREVIEW_COMMAND-}" >&2; return 2 ;;
  esac
}

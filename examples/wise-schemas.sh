#!/usr/bin/env bash

wise_schema_shared() {
  uniopt_option session.name --long --name --dest OV_NAME --metavar NAME --help "Select a named WISE session"
  uniopt_option session.env_file --long --env-file --dest ENV_FILE --type path --metavar PATH --help "Use this session env file"
  uniopt_option compose.extra --long --extra-compose --dest EXTRA_COMPOSE --type path --repeatable --metavar PATH --help "Add a Compose file"
}

wise_schema_env() {
  uniopt_reset
  uniopt_schema wise-env --summary "Generate a WISE session environment" --unknown error
  wise_schema_shared
  uniopt_option network.publish --long --publish --dest PUBLISH --repeatable --metavar SPEC --help "Publish a sidecar port"
  uniopt_option host.open --long --host-open --neg-long --no-host-open --dest HOST_OPEN --type tristate --default inherit --help "Set inherited host-open policy"
  uniopt_option container.mode --long --container-mode --dest CONTAINER_MODE --type enum --choice none --choice sidecar --metavar MODE --help "Select the container mode"
  uniopt_alias container.inner --long --inner-containers --set container.mode sidecar --help "Use sidecar containers"
}

wise_schema_down() {
  uniopt_reset
  uniopt_schema wise-down --unknown error
  wise_schema_shared
  uniopt_option prune.inner --long --prune-inner-containers --dest PRUNE_INNER --type boolean --default false --help "Prune inner containers"
  uniopt_option prune.volumes --dest PRUNE_VOLUMES --type boolean --default false --internal
  uniopt_alias prune.inner_volumes --long --prune-inner-container-volumes --set prune.inner true --set prune.volumes true --help "Prune inner containers and volumes"
}

wise_schema_host_open() {
  uniopt_reset
  uniopt_schema wise-host-open --unknown error
  uniopt_option action.client --long --client --dest CLIENT_URL --metavar URL --help "Send a URL"
  uniopt_option action.client_file --long --client-file --dest CLIENT_FILE --type path --metavar PATH --help "Send a file"
  uniopt_option action.daemon --long --daemon --dest DAEMON --type boolean --default false --help "Start a daemon"
  uniopt_option action.stop --long --stop --dest STOP --type boolean --default false --help "Stop a daemon"
  uniopt_constraint mutex action.client action.client_file action.daemon action.stop
}

wise_schema_shell() {
  uniopt_reset
  uniopt_schema wise-shell --unknown error
  wise_schema_shared
  uniopt_positional shell.command --dest SHELL_ARGS --remainder --metavar COMMAND --help "Command and exact arguments"
}

wise_schema_up() {
  uniopt_reset
  uniopt_schema wise-up --unknown collect --unknown-dest COMPOSE_ARGS
  wise_schema_shared
  uniopt_option build.enabled --long --build --dest DO_BUILD --type boolean --default false --help "Build images"
}

wise_schema_converter() {
  uniopt_reset
  uniopt_schema dockerfile-to-wise-sdk --unknown error
  uniopt_option output.directory --long --output-dir --dest OUTPUT_DIR --type path --required --metavar PATH --help "Output directory"
  uniopt_positional input.dockerfile --dest DOCKERFILE --type path --required --metavar DOCKERFILE --help "Input Dockerfile"
}

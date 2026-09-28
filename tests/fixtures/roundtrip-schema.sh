#!/usr/bin/env bash

roundtrip_dynamic_default() {
  printf -v "$1" '%s' "dynamic value"
}

roundtrip_positive() {
  (( $1 > 0 ))
}

roundtrip_schema() {
  uniopt_reset
  uniopt_schema roundtrip-demo \
    --summary "Round-trip quotes, callbacks, aliases, and exact values" \
    --unknown collect --unknown-dest ROUNDTRIP_UNKNOWN \
    --ui-confirm "Run the round-trip demonstration?"

  uniopt_option text.literal \
    --long --literal --dest LITERAL --default $'two words\n\'quoted\' "$HOME" * ? [x] a\\b $(touch /tmp/uniopt-roundtrip-marker)' \
    --help "Literal adversarial value"
  uniopt_option text.dynamic \
    --long --dynamic --dest DYNAMIC --default-fn roundtrip_dynamic_default \
    --help "Callback-derived value"
  uniopt_option count.positive \
    --long --count --dest COUNT --type uint --default 1 \
    --validator roundtrip_positive --help "Positive count"
  uniopt_option mode.value \
    --long --mode --dest MODE --type enum --choice first --choice second \
    --default first --help "Selected mode"
  uniopt_option flag.left --long --left --dest LEFT --type boolean --default false
  uniopt_option flag.right --long --right --dest RIGHT --type boolean --default false
  uniopt_option value.repeated \
    --long --value --dest VALUES --repeatable --help "Repeat exact values"
  uniopt_alias preset.second \
    --long --second --set mode.value first --set mode.value second \
    --help "Ordered duplicate assignments; the last value wins"
  uniopt_positional input.name \
    --dest INPUT --required --metavar INPUT --help "Required input"
  uniopt_positional command.args \
    --dest COMMAND_ARGS --remainder --metavar ARG --help "Exact command tail"
  uniopt_constraint mutex flag.left flag.right
}

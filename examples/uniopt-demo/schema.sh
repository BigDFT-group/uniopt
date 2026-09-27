#!/usr/bin/env bash

uniopt_demo_default_name() {
  printf -v "$1" '%s' "${USER:-friend}"
}

uniopt_demo_positive() {
  (( $1 > 0 ))
}

uniopt_demo_schema() {
  uniopt_reset
  uniopt_schema uniopt-demo \
    --summary "Build a greeting while demonstrating UniOpt's schema-driven interfaces." \
    --unknown error

  uniopt_option greeting.name \
    --short -n --long --name --dest SENDER --default-fn uniopt_demo_default_name \
    --metavar NAME --help "Name of the sender" \
    --ui-label "Sender name" --ui-group Greeting --ui-order 20 \
    --ui-placeholder "Resolved from USER when omitted"
  uniopt_option greeting.style \
    --short -s --long --style --dest STYLE --type enum --default friendly \
    --choice friendly --choice formal --choice terse \
    --metavar STYLE --help "Greeting style" \
    --ui-label Style --ui-group Greeting --ui-control radio --ui-order 30
  uniopt_option output.path \
    --short -o --long --output --dest OUTPUT --type path --default - \
    --metavar PATH --help "Write to PATH instead of standard output" \
    --ui-label "Output path" --ui-group Output --ui-order 10 \
    --ui-placeholder "- means standard output" --ui-file-mode save
  uniopt_option output.loud \
    --long --loud --dest LOUD --type boolean --default false \
    --help "Use uppercase output" --ui-label "Uppercase output" \
    --ui-group Output --ui-order 20
  uniopt_option output.color \
    --long --color --neg-long --no-color --dest COLOR --type tristate \
    --default inherit --help "Enable, disable, or inherit terminal color" \
    --ui-label Color --ui-group Output --ui-control tristate --ui-order 30
  uniopt_option runtime.jobs \
    --short -j --long --jobs --dest JOBS --type uint --default 1 \
    --validator uniopt_demo_positive --metavar N --help "Positive worker count" \
    --ui-label "Worker count" --ui-group Runtime --ui-control number \
    --ui-order 10 --ui-min 1 --ui-max 32 --ui-step 1
  uniopt_option metadata.tag \
    --short -t --long --tag --dest TAGS --repeatable --metavar TAG \
    --help "Attach a tag; may be repeated" --ui-label Tags \
    --ui-group Metadata --ui-control list --ui-order 10
  uniopt_option debug.sources \
    --long --show-sources --dest SHOW_SOURCES --type boolean --default false \
    --help "Print selected value provenance" --ui-label "Show provenance" \
    --ui-group Diagnostics --ui-advanced --ui-order 10

  uniopt_alias preset.quick \
    --long --quick --set greeting.style terse --set output.loud true \
    --help "Alias for terse, uppercase output" --ui-label "Quick preset" \
    --ui-group Presets --ui-control checkbox --ui-order 10

  uniopt_positional greeting.recipient \
    --dest RECIPIENT --required --metavar RECIPIENT \
    --help "Person or group to greet" --ui-label Recipient \
    --ui-group Greeting --ui-order 10 --ui-placeholder "Ada"
  uniopt_positional greeting.extra \
    --dest EXTRA_WORDS --remainder --metavar WORD \
    --help "Extra words preserved after --" --ui-label "Extra words" \
    --ui-group Advanced --ui-control list --ui-advanced --ui-order 20
}

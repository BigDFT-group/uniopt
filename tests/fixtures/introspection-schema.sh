#!/usr/bin/env bash

uniopt_introspection_fixture() {
  uniopt_reset
  uniopt_schema introspection-fixture
  uniopt_option fixture.value --long --value --dest FIXTURE_VALUE --default safe
}

if [[ "${UNIOPT_INTROSPECT:-0}" != 1 && -n "${UNIOPT_SIDE_EFFECT_MARKER:-}" ]]; then
  printf 'application side effect\n' >"$UNIOPT_SIDE_EFFECT_MARKER"
fi

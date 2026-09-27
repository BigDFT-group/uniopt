#!/usr/bin/env bash
# UniOpt - declarative command-line schemas for Bash 3.2+

if (( BASH_VERSINFO[0] < 3 || (BASH_VERSINFO[0] == 3 && BASH_VERSINFO[1] < 2) )); then
  printf 'UniOpt requires Bash 3.2 or newer\n' >&2
  return 1 2>/dev/null || exit 1
fi

uniopt_reset() {
  UNIOPT_SCHEMA_NAME=""
  UNIOPT_SCHEMA_SUMMARY=""
  UNIOPT_SCHEMA_UI_CONFIRM=""
  UNIOPT_UNKNOWN_POLICY="error"
  UNIOPT_UNKNOWN_DEST=""
  UNIOPT_ERROR=""
  UNIOPT_ACTION=""
  UNIOPT_BUILTIN_REGISTRATION=0
  UNIOPT_ITEMS_COUNT=0
  UNIOPT_CONSTRAINT_COUNT=0
  UNIOPT_CHOICE_COUNT=0
  UNIOPT_SPELLING_COUNT=0
  UNIOPT_SET_COUNT=0
  UNIOPT_ITEM_IDS=()
  UNIOPT_KIND=() UNIOPT_DEST=() UNIOPT_TYPE=()
  UNIOPT_DEFAULT=() UNIOPT_HAS_DEFAULT=() UNIOPT_DEFAULT_FN=() UNIOPT_DEFAULT_ENV=()
  UNIOPT_METAVAR=() UNIOPT_HELP=() UNIOPT_SHORT=() UNIOPT_LONG=() UNIOPT_NEG_LONG=()
  UNIOPT_UI_LABEL=() UNIOPT_UI_GROUP=() UNIOPT_UI_CONTROL=() UNIOPT_UI_PLACEHOLDER=()
  UNIOPT_UI_ADVANCED=() UNIOPT_UI_ORDER=() UNIOPT_UI_MIN=() UNIOPT_UI_MAX=() UNIOPT_UI_STEP=() UNIOPT_UI_FILE_MODE=()
  UNIOPT_REPEATABLE=() UNIOPT_REQUIRED=() UNIOPT_INTERNAL=()
  UNIOPT_VALIDATOR=() UNIOPT_STORE_CONST=() UNIOPT_HAS_STORE_CONST=()
  UNIOPT_SPELLING_TEXT=() UNIOPT_SPELLING_ITEM=()
  UNIOPT_CHOICE_ITEM=() UNIOPT_CHOICE_VALUE=()
  UNIOPT_SET_ACTION=() UNIOPT_SET_TARGET=() UNIOPT_SET_VALUE=()
  UNIOPT_CONSTRAINT_KIND=() UNIOPT_CONSTRAINT_START=() UNIOPT_CONSTRAINT_LENGTH=()
  UNIOPT_CONSTRAINT_MEMBER=()
  UNIOPT_VALUE=() UNIOPT_SOURCE=() UNIOPT_SEEN=()
  UNIOPT_MULTI_ITEM=() UNIOPT_MULTI_VALUE=()
  UNIOPT_UNKNOWN_VALUES=()
  UNIOPT_RESULT=()
  UNIOPT_FOUND_INDEX=""
}

uniopt_reset

uniopt__fail() {
  UNIOPT_ERROR="$1"
  printf 'uniopt: %s\n' "$1" >&2
  return 2
}

uniopt__valid_id() { [[ "$1" =~ ^[a-z][a-z0-9_.-]*$ ]]; }
uniopt__valid_dest() { [[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; }

uniopt__find_id() {
  local sought="$1" i
  UNIOPT_FOUND_INDEX=""
  i=0
  while (( i < UNIOPT_ITEMS_COUNT )); do
    if [[ "${UNIOPT_ITEM_IDS[$i]}" == "$sought" ]]; then UNIOPT_FOUND_INDEX="$i"; return 0; fi
    i=$((i + 1))
  done
  return 1
}

uniopt__find_spelling() {
  local sought="$1" i
  UNIOPT_FOUND_INDEX=""
  i=0
  while (( i < UNIOPT_SPELLING_COUNT )); do
    if [[ "${UNIOPT_SPELLING_TEXT[$i]}" == "$sought" ]]; then UNIOPT_FOUND_INDEX="${UNIOPT_SPELLING_ITEM[$i]}"; return 0; fi
    i=$((i + 1))
  done
  return 1
}

uniopt_schema() {
  (( $# >= 1 )) || { uniopt__fail "schema requires a command name"; return; }
  UNIOPT_SCHEMA_NAME="$1"; shift
  while (( $# )); do
    case "$1" in
      --summary) (( $# >= 2 )) || { uniopt__fail "--summary requires a value"; return; }; UNIOPT_SCHEMA_SUMMARY="$2"; shift 2 ;;
      --ui-confirm) (( $# >= 2 )) || { uniopt__fail "--ui-confirm requires a value"; return; }; UNIOPT_SCHEMA_UI_CONFIRM="$2"; shift 2 ;;
      --unknown) (( $# >= 2 )) || { uniopt__fail "--unknown requires a policy"; return; }; UNIOPT_UNKNOWN_POLICY="$2"; shift 2 ;;
      --unknown-dest) (( $# >= 2 )) || { uniopt__fail "--unknown-dest requires a variable"; return; }; UNIOPT_UNKNOWN_DEST="$2"; shift 2 ;;
      *) uniopt__fail "unknown schema attribute: $1"; return ;;
    esac
  done
  case "$UNIOPT_UNKNOWN_POLICY" in error|collect|stop) ;; *) uniopt__fail "invalid unknown-option policy: $UNIOPT_UNKNOWN_POLICY"; return ;; esac
  if [[ "$UNIOPT_UNKNOWN_POLICY" != error ]]; then
    uniopt__valid_dest "$UNIOPT_UNKNOWN_DEST" || { uniopt__fail "$UNIOPT_UNKNOWN_POLICY policy requires --unknown-dest VARIABLE"; return; }
  fi
  UNIOPT_BUILTIN_REGISTRATION=1
  uniopt_option interface.help --short -h --long --help --dest UNIOPT_BUILTIN_HELP \
    --type boolean --default false --help "Show help and exit" --ui-control hidden || { UNIOPT_BUILTIN_REGISTRATION=0; return; }
  uniopt_option interface.gui --long --gui --dest UNIOPT_BUILTIN_GUI \
    --type boolean --default false --help "Open the graphical command-line advisor" --ui-control hidden || { UNIOPT_BUILTIN_REGISTRATION=0; return; }
  UNIOPT_BUILTIN_REGISTRATION=0
}

uniopt__new_item() {
  local id="$1" kind="$2" i
  uniopt__valid_id "$id" || { uniopt__fail "invalid semantic ID: $id"; return; }
  if uniopt__find_id "$id"; then uniopt__fail "duplicate semantic ID: $id"; return; fi
  i=$UNIOPT_ITEMS_COUNT; UNIOPT_ITEMS_COUNT=$((UNIOPT_ITEMS_COUNT + 1)); UNIOPT_FOUND_INDEX="$i"
  UNIOPT_ITEM_IDS[$i]="$id"; UNIOPT_KIND[$i]="$kind"; UNIOPT_DEST[$i]=""; UNIOPT_TYPE[$i]="string"
  UNIOPT_DEFAULT[$i]=""; UNIOPT_HAS_DEFAULT[$i]=0; UNIOPT_DEFAULT_FN[$i]=""; UNIOPT_DEFAULT_ENV[$i]=""
  UNIOPT_METAVAR[$i]=""; UNIOPT_HELP[$i]=""; UNIOPT_SHORT[$i]=""; UNIOPT_LONG[$i]=""; UNIOPT_NEG_LONG[$i]=""
  UNIOPT_UI_LABEL[$i]=""; UNIOPT_UI_GROUP[$i]=""; UNIOPT_UI_CONTROL[$i]="auto"; UNIOPT_UI_PLACEHOLDER[$i]=""
  UNIOPT_UI_ADVANCED[$i]=0; UNIOPT_UI_ORDER[$i]=""; UNIOPT_UI_MIN[$i]=""; UNIOPT_UI_MAX[$i]=""; UNIOPT_UI_STEP[$i]=""; UNIOPT_UI_FILE_MODE[$i]="auto"
  UNIOPT_REPEATABLE[$i]=0; UNIOPT_REQUIRED[$i]=0; UNIOPT_INTERNAL[$i]=0; UNIOPT_VALIDATOR[$i]=""
  UNIOPT_STORE_CONST[$i]=""; UNIOPT_HAS_STORE_CONST[$i]=0; UNIOPT_VALUE[$i]=""; UNIOPT_SOURCE[$i]="unset"; UNIOPT_SEEN[$i]=0
}

uniopt__add_spelling() {
  local item="$1" spelling="$2" i
  if uniopt__find_spelling "$spelling"; then uniopt__fail "duplicate CLI spelling: $spelling"; return; fi
  i=$UNIOPT_SPELLING_COUNT; UNIOPT_SPELLING_COUNT=$((UNIOPT_SPELLING_COUNT + 1))
  UNIOPT_SPELLING_TEXT[$i]="$spelling"; UNIOPT_SPELLING_ITEM[$i]="$item"
}

uniopt_option() {
  (( $# >= 1 )) || { uniopt__fail "option requires an ID"; return; }
  local id="$1" item choice i; shift
  uniopt__new_item "$id" option || return; item="$UNIOPT_FOUND_INDEX"
  while (( $# )); do
    case "$1" in
      --dest) (( $# >= 2 )) || { uniopt__fail "$id: --dest requires a value"; return; }; UNIOPT_DEST[$item]="$2"; shift 2 ;;
      --type) (( $# >= 2 )) || { uniopt__fail "$id: --type requires a value"; return; }; UNIOPT_TYPE[$item]="$2"; shift 2 ;;
      --default) (( $# >= 2 )) || { uniopt__fail "$id: --default requires a value"; return; }; UNIOPT_DEFAULT[$item]="$2"; UNIOPT_HAS_DEFAULT[$item]=1; shift 2 ;;
      --default-fn) (( $# >= 2 )) || { uniopt__fail "$id: --default-fn requires a value"; return; }; UNIOPT_DEFAULT_FN[$item]="$2"; shift 2 ;;
      --default-env) (( $# >= 2 )) || { uniopt__fail "$id: --default-env requires a value"; return; }; UNIOPT_DEFAULT_ENV[$item]="$2"; shift 2 ;;
      --metavar) (( $# >= 2 )) || { uniopt__fail "$id: --metavar requires a value"; return; }; UNIOPT_METAVAR[$item]="$2"; shift 2 ;;
      --help) (( $# >= 2 )) || { uniopt__fail "$id: --help requires a value"; return; }; UNIOPT_HELP[$item]="$2"; shift 2 ;;
      --ui-label) (( $# >= 2 )) || { uniopt__fail "$id: --ui-label requires a value"; return; }; UNIOPT_UI_LABEL[$item]="$2"; shift 2 ;;
      --ui-group) (( $# >= 2 )) || { uniopt__fail "$id: --ui-group requires a value"; return; }; UNIOPT_UI_GROUP[$item]="$2"; shift 2 ;;
      --ui-control) (( $# >= 2 )) || { uniopt__fail "$id: --ui-control requires a value"; return; }; UNIOPT_UI_CONTROL[$item]="$2"; shift 2 ;;
      --ui-placeholder) (( $# >= 2 )) || { uniopt__fail "$id: --ui-placeholder requires a value"; return; }; UNIOPT_UI_PLACEHOLDER[$item]="$2"; shift 2 ;;
      --ui-advanced) UNIOPT_UI_ADVANCED[$item]=1; shift ;;
      --ui-order) (( $# >= 2 )) || { uniopt__fail "$id: --ui-order requires a value"; return; }; UNIOPT_UI_ORDER[$item]="$2"; shift 2 ;;
      --ui-min) (( $# >= 2 )) || { uniopt__fail "$id: --ui-min requires a value"; return; }; UNIOPT_UI_MIN[$item]="$2"; shift 2 ;;
      --ui-max) (( $# >= 2 )) || { uniopt__fail "$id: --ui-max requires a value"; return; }; UNIOPT_UI_MAX[$item]="$2"; shift 2 ;;
      --ui-step) (( $# >= 2 )) || { uniopt__fail "$id: --ui-step requires a value"; return; }; UNIOPT_UI_STEP[$item]="$2"; shift 2 ;;
      --ui-file-mode) (( $# >= 2 )) || { uniopt__fail "$id: --ui-file-mode requires a value"; return; }; UNIOPT_UI_FILE_MODE[$item]="$2"; shift 2 ;;
      --short) (( $# >= 2 )) || { uniopt__fail "$id: --short requires a value"; return; }; UNIOPT_SHORT[$item]="$2"; shift 2 ;;
      --long) (( $# >= 2 )) || { uniopt__fail "$id: --long requires a value"; return; }; UNIOPT_LONG[$item]="$2"; shift 2 ;;
      --neg-long) (( $# >= 2 )) || { uniopt__fail "$id: --neg-long requires a value"; return; }; UNIOPT_NEG_LONG[$item]="$2"; shift 2 ;;
      --repeatable) UNIOPT_REPEATABLE[$item]=1; shift ;;
      --required) UNIOPT_REQUIRED[$item]=1; shift ;;
      --internal) UNIOPT_INTERNAL[$item]=1; shift ;;
      --choice)
        (( $# >= 2 )) || { uniopt__fail "$id: --choice requires a value"; return; }
        i=$UNIOPT_CHOICE_COUNT; UNIOPT_CHOICE_COUNT=$((UNIOPT_CHOICE_COUNT + 1)); UNIOPT_CHOICE_ITEM[$i]="$item"; UNIOPT_CHOICE_VALUE[$i]="$2"; shift 2 ;;
      --validator) (( $# >= 2 )) || { uniopt__fail "$id: --validator requires a value"; return; }; UNIOPT_VALIDATOR[$item]="$2"; shift 2 ;;
      --store-const) (( $# >= 2 )) || { uniopt__fail "$id: --store-const requires a value"; return; }; UNIOPT_STORE_CONST[$item]="$2"; UNIOPT_HAS_STORE_CONST[$item]=1; shift 2 ;;
      *) uniopt__fail "unknown option attribute for $id: $1"; return ;;
    esac
  done
  uniopt__valid_dest "${UNIOPT_DEST[$item]}" || { uniopt__fail "$id requires a valid --dest"; return; }
  [[ -n "${UNIOPT_SHORT[$item]}${UNIOPT_LONG[$item]}" || "${UNIOPT_INTERNAL[$item]}" == 1 ]] || { uniopt__fail "$id requires --short or --long"; return; }
  [[ -z "${UNIOPT_SHORT[$item]}" || "${UNIOPT_SHORT[$item]}" =~ ^-[^-]$ ]] || { uniopt__fail "invalid short spelling for $id"; return; }
  [[ -z "${UNIOPT_LONG[$item]}" || "${UNIOPT_LONG[$item]}" =~ ^--[a-zA-Z0-9][a-zA-Z0-9-]*$ ]] || { uniopt__fail "invalid long spelling for $id"; return; }
  [[ -z "${UNIOPT_NEG_LONG[$item]}" || "${UNIOPT_NEG_LONG[$item]}" =~ ^--[a-zA-Z0-9][a-zA-Z0-9-]*$ ]] || { uniopt__fail "invalid negative spelling for $id"; return; }
  if [[ "$UNIOPT_BUILTIN_REGISTRATION" != 1 ]]; then
    [[ "${UNIOPT_SHORT[$item]}" != -h && "${UNIOPT_LONG[$item]}" != --help && "${UNIOPT_LONG[$item]}" != --gui && "${UNIOPT_NEG_LONG[$item]}" != --help && "${UNIOPT_NEG_LONG[$item]}" != --gui ]] || { uniopt__fail "$id uses a reserved UniOpt control spelling"; return; }
  fi
  case "${UNIOPT_TYPE[$item]}" in string|path|int|integer|uint|enum|boolean|tristate) ;; *) uniopt__fail "invalid type for $id: ${UNIOPT_TYPE[$item]}"; return ;; esac
  case "${UNIOPT_UI_CONTROL[$item]}" in auto|text|textarea|password|number|select|radio|checkbox|tristate|file|directory|list|hidden) ;; *) uniopt__fail "invalid UI control for $id: ${UNIOPT_UI_CONTROL[$item]}"; return ;; esac
  case "${UNIOPT_UI_FILE_MODE[$item]}" in auto|open|save|directory) ;; *) uniopt__fail "invalid UI file mode for $id: ${UNIOPT_UI_FILE_MODE[$item]}"; return ;; esac
  [[ "${UNIOPT_TYPE[$item]}" == path || "${UNIOPT_UI_FILE_MODE[$item]}" == auto ]] || { uniopt__fail "$id uses --ui-file-mode but is not a path"; return; }
  [[ -z "${UNIOPT_UI_ORDER[$item]}" || "${UNIOPT_UI_ORDER[$item]}" =~ ^-?[0-9]+$ ]] || { uniopt__fail "$id UI order must be an integer"; return; }
  [[ -z "${UNIOPT_NEG_LONG[$item]}" || "${UNIOPT_TYPE[$item]}" == boolean || "${UNIOPT_TYPE[$item]}" == tristate ]] || { uniopt__fail "$id has a negative spelling but is not boolean or tristate"; return; }
  local defaults=0
  (( UNIOPT_HAS_DEFAULT[$item] == 1 )) && defaults=$((defaults + 1))
  [[ -n "${UNIOPT_DEFAULT_FN[$item]}" ]] && defaults=$((defaults + 1))
  [[ -n "${UNIOPT_DEFAULT_ENV[$item]}" ]] && defaults=$((defaults + 1))
  (( defaults <= 1 )) || { uniopt__fail "$id cannot have multiple default sources"; return; }
  [[ "${UNIOPT_REPEATABLE[$item]}" != 1 || "$defaults" == 0 ]] || { uniopt__fail "$id repeatable arrays cannot have scalar defaults"; return; }
  if [[ -n "${UNIOPT_DEFAULT_ENV[$item]}" ]]; then uniopt__valid_dest "${UNIOPT_DEFAULT_ENV[$item]}" || { uniopt__fail "$id has an invalid environment variable name"; return; }; fi
  if [[ -n "${UNIOPT_SHORT[$item]}" ]]; then uniopt__add_spelling "$item" "${UNIOPT_SHORT[$item]}" || return; fi
  if [[ -n "${UNIOPT_LONG[$item]}" ]]; then uniopt__add_spelling "$item" "${UNIOPT_LONG[$item]}" || return; fi
  if [[ -n "${UNIOPT_NEG_LONG[$item]}" ]]; then uniopt__add_spelling "$item" "${UNIOPT_NEG_LONG[$item]}" || return; fi
}

uniopt_alias() {
  (( $# >= 1 )) || { uniopt__fail "alias requires an ID"; return; }
  local id="$1" item target target_item i; shift
  uniopt__new_item "$id" alias || return; item="$UNIOPT_FOUND_INDEX"
  while (( $# )); do
    case "$1" in
      --short) (( $# >= 2 )) || { uniopt__fail "$id: --short requires a value"; return; }; UNIOPT_SHORT[$item]="$2"; shift 2 ;;
      --long) (( $# >= 2 )) || { uniopt__fail "$id: --long requires a value"; return; }; UNIOPT_LONG[$item]="$2"; shift 2 ;;
      --help) (( $# >= 2 )) || { uniopt__fail "$id: --help requires a value"; return; }; UNIOPT_HELP[$item]="$2"; shift 2 ;;
      --ui-label) (( $# >= 2 )) || { uniopt__fail "$id: --ui-label requires a value"; return; }; UNIOPT_UI_LABEL[$item]="$2"; shift 2 ;;
      --ui-group) (( $# >= 2 )) || { uniopt__fail "$id: --ui-group requires a value"; return; }; UNIOPT_UI_GROUP[$item]="$2"; shift 2 ;;
      --ui-control) (( $# >= 2 )) || { uniopt__fail "$id: --ui-control requires a value"; return; }; UNIOPT_UI_CONTROL[$item]="$2"; shift 2 ;;
      --ui-placeholder) (( $# >= 2 )) || { uniopt__fail "$id: --ui-placeholder requires a value"; return; }; UNIOPT_UI_PLACEHOLDER[$item]="$2"; shift 2 ;;
      --ui-advanced) UNIOPT_UI_ADVANCED[$item]=1; shift ;;
      --ui-order) (( $# >= 2 )) || { uniopt__fail "$id: --ui-order requires a value"; return; }; UNIOPT_UI_ORDER[$item]="$2"; shift 2 ;;
      --set)
        (( $# >= 3 )) || { uniopt__fail "$id: --set requires ID and VALUE"; return; }
        target="$2"; uniopt__find_id "$target" || { uniopt__fail "$id sets unknown option ID: $target"; return; }; target_item="$UNIOPT_FOUND_INDEX"
        [[ "${UNIOPT_KIND[$target_item]}" == option ]] || { uniopt__fail "$id sets non-option ID: $target"; return; }
        i=$UNIOPT_SET_COUNT; UNIOPT_SET_COUNT=$((UNIOPT_SET_COUNT + 1)); UNIOPT_SET_ACTION[$i]="$item"; UNIOPT_SET_TARGET[$i]="$target_item"; UNIOPT_SET_VALUE[$i]="$3"; shift 3 ;;
      *) uniopt__fail "unknown alias attribute for $id: $1"; return ;;
    esac
  done
  local found=0; i=0; while (( i < UNIOPT_SET_COUNT )); do [[ "${UNIOPT_SET_ACTION[$i]}" == "$item" ]] && found=1; i=$((i + 1)); done
  (( found )) || { uniopt__fail "$id requires at least one --set ID VALUE"; return; }
  [[ -n "${UNIOPT_SHORT[$item]}${UNIOPT_LONG[$item]}" ]] || { uniopt__fail "$id requires --short or --long"; return; }
  [[ "${UNIOPT_SHORT[$item]}" != -h && "${UNIOPT_LONG[$item]}" != --help && "${UNIOPT_LONG[$item]}" != --gui ]] || { uniopt__fail "$id uses a reserved UniOpt control spelling"; return; }
  case "${UNIOPT_UI_CONTROL[$item]}" in auto|text|textarea|password|number|select|radio|checkbox|tristate|file|directory|list|hidden) ;; *) uniopt__fail "invalid UI control for $id: ${UNIOPT_UI_CONTROL[$item]}"; return ;; esac
  [[ -z "${UNIOPT_UI_ORDER[$item]}" || "${UNIOPT_UI_ORDER[$item]}" =~ ^-?[0-9]+$ ]] || { uniopt__fail "$id UI order must be an integer"; return; }
  if [[ -n "${UNIOPT_SHORT[$item]}" ]]; then uniopt__add_spelling "$item" "${UNIOPT_SHORT[$item]}" || return; fi
  if [[ -n "${UNIOPT_LONG[$item]}" ]]; then uniopt__add_spelling "$item" "${UNIOPT_LONG[$item]}" || return; fi
}

uniopt_positional() {
  (( $# >= 1 )) || { uniopt__fail "positional requires an ID"; return; }
  local id="$1" item choice kind=positional; shift
  for choice in "$@"; do [[ "$choice" == --remainder ]] && kind=remainder; done
  uniopt__new_item "$id" "$kind" || return; item="$UNIOPT_FOUND_INDEX"
  while (( $# )); do
    case "$1" in
      --dest) (( $# >= 2 )) || { uniopt__fail "$id: --dest requires a value"; return; }; UNIOPT_DEST[$item]="$2"; shift 2 ;;
      --type) (( $# >= 2 )) || { uniopt__fail "$id: --type requires a value"; return; }; UNIOPT_TYPE[$item]="$2"; shift 2 ;;
      --metavar) (( $# >= 2 )) || { uniopt__fail "$id: --metavar requires a value"; return; }; UNIOPT_METAVAR[$item]="$2"; shift 2 ;;
      --help) (( $# >= 2 )) || { uniopt__fail "$id: --help requires a value"; return; }; UNIOPT_HELP[$item]="$2"; shift 2 ;;
      --ui-label) (( $# >= 2 )) || { uniopt__fail "$id: --ui-label requires a value"; return; }; UNIOPT_UI_LABEL[$item]="$2"; shift 2 ;;
      --ui-group) (( $# >= 2 )) || { uniopt__fail "$id: --ui-group requires a value"; return; }; UNIOPT_UI_GROUP[$item]="$2"; shift 2 ;;
      --ui-control) (( $# >= 2 )) || { uniopt__fail "$id: --ui-control requires a value"; return; }; UNIOPT_UI_CONTROL[$item]="$2"; shift 2 ;;
      --ui-placeholder) (( $# >= 2 )) || { uniopt__fail "$id: --ui-placeholder requires a value"; return; }; UNIOPT_UI_PLACEHOLDER[$item]="$2"; shift 2 ;;
      --ui-advanced) UNIOPT_UI_ADVANCED[$item]=1; shift ;;
      --ui-order) (( $# >= 2 )) || { uniopt__fail "$id: --ui-order requires a value"; return; }; UNIOPT_UI_ORDER[$item]="$2"; shift 2 ;;
      --ui-file-mode) (( $# >= 2 )) || { uniopt__fail "$id: --ui-file-mode requires a value"; return; }; UNIOPT_UI_FILE_MODE[$item]="$2"; shift 2 ;;
      --required) UNIOPT_REQUIRED[$item]=1; shift ;;
      --remainder) UNIOPT_KIND[$item]=remainder; UNIOPT_REPEATABLE[$item]=1; shift ;;
      --validator) (( $# >= 2 )) || { uniopt__fail "$id: --validator requires a value"; return; }; UNIOPT_VALIDATOR[$item]="$2"; shift 2 ;;
      *) uniopt__fail "unknown positional attribute for $id: $1"; return ;;
    esac
  done
  uniopt__valid_dest "${UNIOPT_DEST[$item]}" || { uniopt__fail "$id requires a valid --dest"; return; }
  case "${UNIOPT_TYPE[$item]}" in string|path|int|integer|uint|enum|boolean|tristate) ;; *) uniopt__fail "invalid type for $id: ${UNIOPT_TYPE[$item]}"; return ;; esac
  case "${UNIOPT_UI_CONTROL[$item]}" in auto|text|textarea|password|number|select|radio|checkbox|tristate|file|directory|list|hidden) ;; *) uniopt__fail "invalid UI control for $id: ${UNIOPT_UI_CONTROL[$item]}"; return ;; esac
  case "${UNIOPT_UI_FILE_MODE[$item]}" in auto|open|save|directory) ;; *) uniopt__fail "invalid UI file mode for $id: ${UNIOPT_UI_FILE_MODE[$item]}"; return ;; esac
  [[ "${UNIOPT_TYPE[$item]}" == path || "${UNIOPT_UI_FILE_MODE[$item]}" == auto ]] || { uniopt__fail "$id uses --ui-file-mode but is not a path"; return; }
  [[ -z "${UNIOPT_UI_ORDER[$item]}" || "${UNIOPT_UI_ORDER[$item]}" =~ ^-?[0-9]+$ ]] || { uniopt__fail "$id UI order must be an integer"; return; }
}

uniopt_constraint() {
  (( $# >= 3 )) || { uniopt__fail "constraint requires KIND and at least two IDs"; return; }
  local kind="$1" c start item; shift
  case "$kind" in mutex|requires|conflicts|one-of|one_of) ;; *) uniopt__fail "unknown constraint kind: $kind"; return ;; esac
  [[ "$kind" != requires && "$kind" != conflicts || $# -eq 2 ]] || { uniopt__fail "$kind constraint needs exactly two IDs"; return; }
  c=$UNIOPT_CONSTRAINT_COUNT; UNIOPT_CONSTRAINT_COUNT=$((UNIOPT_CONSTRAINT_COUNT + 1)); start=${#UNIOPT_CONSTRAINT_MEMBER[@]}
  UNIOPT_CONSTRAINT_KIND[$c]="$kind"; UNIOPT_CONSTRAINT_START[$c]="$start"; UNIOPT_CONSTRAINT_LENGTH[$c]="$#"
  while (( $# )); do
    uniopt__find_id "$1" || { uniopt__fail "constraint references unknown ID: $1"; return; }; item="$UNIOPT_FOUND_INDEX"
    UNIOPT_CONSTRAINT_MEMBER[${#UNIOPT_CONSTRAINT_MEMBER[@]}]="$item"; shift
  done
}

uniopt__validate_value() {
  local item="$1" value="$2" i found=0 validator="${UNIOPT_VALIDATOR[$1]}" id="${UNIOPT_ITEM_IDS[$1]}"
  case "${UNIOPT_TYPE[$item]}" in
    string|path) ;;
    boolean) [[ "$value" == true || "$value" == false ]] || { uniopt__fail "$id expects true or false, got: $value"; return; } ;;
    tristate) [[ "$value" == true || "$value" == false || "$value" == inherit ]] || { uniopt__fail "$id expects true, false, or inherit, got: $value"; return; } ;;
    int|integer) [[ "$value" =~ ^-?[0-9]+$ ]] || { uniopt__fail "$id expects an integer, got: $value"; return; } ;;
    uint) [[ "$value" =~ ^[0-9]+$ ]] || { uniopt__fail "$id expects a non-negative integer, got: $value"; return; } ;;
    enum)
      i=0; while (( i < UNIOPT_CHOICE_COUNT )); do [[ "${UNIOPT_CHOICE_ITEM[$i]}" == "$item" && "${UNIOPT_CHOICE_VALUE[$i]}" == "$value" ]] && found=1; i=$((i + 1)); done
      (( found )) || { uniopt__fail "$id has invalid value: $value"; return; }
      ;;
  esac
  if [[ -n "$validator" ]]; then
    declare -F "$validator" >/dev/null || { uniopt__fail "$id validator is not a function: $validator"; return; }
    "$validator" "$value" || { uniopt__fail "$id rejected value: $value"; return; }
  fi
}

uniopt__set_scalar() {
  local item="$1" value="$2" source="$3" dest="${UNIOPT_DEST[$1]}"
  UNIOPT_VALUE[$item]="$value"; UNIOPT_SOURCE[$item]="$source"
  printf -v "$dest" '%s' "$value"
}

uniopt__append_multi() {
  local item="$1" value="$2" source="$3" i=${#UNIOPT_MULTI_ITEM[@]}
  UNIOPT_MULTI_ITEM[$i]="$item"; UNIOPT_MULTI_VALUE[$i]="$value"; UNIOPT_SOURCE[$item]="$source"
}

uniopt__assign() {
  local item="$1" value="$2" source="$3"
  uniopt__validate_value "$item" "$value" || return
  if [[ "${UNIOPT_REPEATABLE[$item]}" == 1 ]]; then uniopt__append_multi "$item" "$value" "$source"; else uniopt__set_scalar "$item" "$value" "$source"; fi
  UNIOPT_SEEN[$item]=$((${UNIOPT_SEEN[$item]} + 1))
}

uniopt__takes_value() {
  local item="$1"
  [[ "${UNIOPT_KIND[$item]}" == option && "${UNIOPT_TYPE[$item]}" != boolean && "${UNIOPT_TYPE[$item]}" != tristate && "${UNIOPT_HAS_STORE_CONST[$item]}" != 1 ]]
}

uniopt__consume_option() {
  local spelling="$1" attached="$2" has_attached="$3" item value i target
  uniopt__find_spelling "$spelling" || return 1; item="$UNIOPT_FOUND_INDEX"
  if [[ "${UNIOPT_KIND[$item]}" == alias ]]; then
    (( has_attached == 0 )) || { uniopt__fail "$spelling does not take a value"; return; }
    UNIOPT_SEEN[$item]=$((${UNIOPT_SEEN[$item]} + 1)); UNIOPT_SOURCE[$item]="cli:$spelling"
    i=0; while (( i < UNIOPT_SET_COUNT )); do
      if [[ "${UNIOPT_SET_ACTION[$i]}" == "$item" ]]; then target="${UNIOPT_SET_TARGET[$i]}"; uniopt__assign "$target" "${UNIOPT_SET_VALUE[$i]}" "cli:$spelling" || return; fi
      i=$((i + 1))
    done
    return 0
  fi
  if [[ "${UNIOPT_HAS_STORE_CONST[$item]}" == 1 ]]; then
    (( has_attached == 0 )) || { uniopt__fail "$spelling does not take a value"; return; }; value="${UNIOPT_STORE_CONST[$item]}"
  elif [[ "${UNIOPT_TYPE[$item]}" == boolean || "${UNIOPT_TYPE[$item]}" == tristate ]]; then
    (( has_attached == 0 )) || { uniopt__fail "$spelling does not take a value"; return; }; value=true
    [[ "$spelling" == "${UNIOPT_NEG_LONG[$item]}" ]] && value=false
  else
    (( has_attached == 1 )) || return 3; value="$attached"
  fi
  uniopt__assign "$item" "$value" "cli:$spelling"
}

uniopt_parse() {
  UNIOPT_ERROR=""; UNIOPT_ACTION=""; UNIOPT_MULTI_ITEM=(); UNIOPT_MULTI_VALUE=(); UNIOPT_UNKNOWN_VALUES=(); UNIOPT_RESULT=()
  local i item value env_name source arg spelling attached has_attached status positional_index=0 end_options=0
  local positional_count=0 remainder_item="" unknown_i=0
  local positional_items=()
  i=0
  while (( i < UNIOPT_ITEMS_COUNT )); do
    UNIOPT_VALUE[$i]=""; UNIOPT_SOURCE[$i]="unset"; UNIOPT_SEEN[$i]=0
    case "${UNIOPT_KIND[$i]}" in
      positional) positional_items[$positional_count]="$i"; positional_count=$((positional_count + 1)); printf -v "${UNIOPT_DEST[$i]}" '%s' "" ;;
      remainder) remainder_item="$i" ;;
      option)
        if [[ "${UNIOPT_REPEATABLE[$i]}" == 1 ]]; then :
        elif [[ -n "${UNIOPT_DEFAULT_FN[$i]}" ]]; then
          declare -F "${UNIOPT_DEFAULT_FN[$i]}" >/dev/null || { uniopt__fail "${UNIOPT_ITEM_IDS[$i]} default function is missing: ${UNIOPT_DEFAULT_FN[$i]}"; return; }
          value=""; "${UNIOPT_DEFAULT_FN[$i]}" value || { uniopt__fail "${UNIOPT_ITEM_IDS[$i]} dynamic default failed"; return; }
          uniopt__validate_value "$i" "$value" || return; uniopt__set_scalar "$i" "$value" "dynamic:${UNIOPT_DEFAULT_FN[$i]}"
        elif [[ -n "${UNIOPT_DEFAULT_ENV[$i]}" ]]; then
          env_name="${UNIOPT_DEFAULT_ENV[$i]}"; declare -p "$env_name" >/dev/null 2>&1 || { uniopt__fail "${UNIOPT_ITEM_IDS[$i]} environment default is unset: $env_name"; return; }
          value="${!env_name}"; uniopt__validate_value "$i" "$value" || return; uniopt__set_scalar "$i" "$value" "env:$env_name"
        elif [[ "${UNIOPT_HAS_DEFAULT[$i]}" == 1 ]]; then
          value="${UNIOPT_DEFAULT[$i]}"; uniopt__validate_value "$i" "$value" || return; source=default
          [[ "${UNIOPT_TYPE[$i]}" == tristate && "$value" == inherit ]] && source=inherited
          uniopt__set_scalar "$i" "$value" "$source"
        else printf -v "${UNIOPT_DEST[$i]}" '%s' ""
        fi
        ;;
    esac
    i=$((i + 1))
  done

  while (( $# )); do
    arg="$1"; shift
    if (( end_options == 0 )) && [[ "$arg" == -- ]]; then
      end_options=1
      if [[ -n "$remainder_item" ]]; then
        while (( $# )); do uniopt__append_multi "$remainder_item" "$1" "cli:--"; UNIOPT_SEEN[$remainder_item]=$((${UNIOPT_SEEN[$remainder_item]} + 1)); shift; done
        break
      fi
      continue
    fi
    if (( end_options == 0 )) && [[ "$arg" == --*=* ]]; then spelling="${arg%%=*}"; attached="${arg#*=}"; has_attached=1; else spelling="$arg"; attached=""; has_attached=0; fi
    if (( end_options == 0 )) && uniopt__find_spelling "$spelling"; then
      if uniopt__consume_option "$spelling" "$attached" "$has_attached"; then status=0; else status=$?; fi
      if (( status == 3 )); then
        (( $# )) || { uniopt__fail "$spelling requires a value"; return; }
        value="$1"; shift; uniopt__consume_option "$spelling" "$value" 1 || return
      elif (( status != 0 )); then return "$status"; fi
      continue
    fi
    if (( end_options == 0 )) && [[ "$arg" == -* ]]; then
      case "$UNIOPT_UNKNOWN_POLICY" in
        error) uniopt__fail "unknown option: $arg"; return ;;
        collect) UNIOPT_UNKNOWN_VALUES[$unknown_i]="$arg"; unknown_i=$((unknown_i + 1)); continue ;;
        stop)
          UNIOPT_UNKNOWN_VALUES[$unknown_i]="$arg"; unknown_i=$((unknown_i + 1))
          while (( $# )); do UNIOPT_UNKNOWN_VALUES[$unknown_i]="$1"; unknown_i=$((unknown_i + 1)); shift; done; break ;;
      esac
    fi
    if (( positional_index < positional_count )); then
      item="${positional_items[$positional_index]}"; positional_index=$((positional_index + 1)); uniopt__assign "$item" "$arg" positional || return
    elif [[ -n "$remainder_item" ]]; then
      uniopt__append_multi "$remainder_item" "$arg" positional; UNIOPT_SEEN[$remainder_item]=$((${UNIOPT_SEEN[$remainder_item]} + 1))
    elif [[ "$UNIOPT_UNKNOWN_POLICY" == error ]]; then uniopt__fail "unexpected positional argument: $arg"; return
    elif [[ "$UNIOPT_UNKNOWN_POLICY" == collect ]]; then UNIOPT_UNKNOWN_VALUES[$unknown_i]="$arg"; unknown_i=$((unknown_i + 1))
    else
      UNIOPT_UNKNOWN_VALUES[$unknown_i]="$arg"; unknown_i=$((unknown_i + 1))
      while (( $# )); do UNIOPT_UNKNOWN_VALUES[$unknown_i]="$1"; unknown_i=$((unknown_i + 1)); shift; done; break
    fi
  done
  if [[ "${UNIOPT_BUILTIN_HELP:-false}" == true ]]; then UNIOPT_ACTION=help; return 0; fi
  if [[ "${UNIOPT_BUILTIN_GUI:-false}" == true ]]; then UNIOPT_ACTION=gui; return 0; fi
  i=0; while (( i < UNIOPT_ITEMS_COUNT )); do
    if [[ "${UNIOPT_REQUIRED[$i]}" == 1 && "${UNIOPT_SEEN[$i]}" == 0 ]]; then uniopt__fail "required ${UNIOPT_KIND[$i]} missing: ${UNIOPT_ITEM_IDS[$i]}"; return; fi
    i=$((i + 1))
  done
  uniopt_validate
}

uniopt_validate() {
  local c=0 start length j item count kind labels
  while (( c < UNIOPT_CONSTRAINT_COUNT )); do
    kind="${UNIOPT_CONSTRAINT_KIND[$c]}"; start="${UNIOPT_CONSTRAINT_START[$c]}"; length="${UNIOPT_CONSTRAINT_LENGTH[$c]}"; count=0; labels=""; j=0
    while (( j < length )); do item="${UNIOPT_CONSTRAINT_MEMBER[$((start + j))]}"; (( UNIOPT_SEEN[$item] > 0 )) && count=$((count + 1)); labels+="${labels:+ }${UNIOPT_ITEM_IDS[$item]}"; j=$((j + 1)); done
    case "$kind" in
      mutex) (( count <= 1 )) || { uniopt__fail "mutually exclusive arguments used: $labels"; return; } ;;
      one-of|one_of) (( count == 1 )) || { uniopt__fail "exactly one argument is required: $labels"; return; } ;;
      requires)
        item="${UNIOPT_CONSTRAINT_MEMBER[$start]}"; j="${UNIOPT_CONSTRAINT_MEMBER[$((start + 1))]}"
        (( UNIOPT_SEEN[$item] == 0 || UNIOPT_SEEN[$j] > 0 )) || { uniopt__fail "${UNIOPT_ITEM_IDS[$item]} requires ${UNIOPT_ITEM_IDS[$j]}"; return; }
        ;;
      conflicts)
        item="${UNIOPT_CONSTRAINT_MEMBER[$start]}"; j="${UNIOPT_CONSTRAINT_MEMBER[$((start + 1))]}"
        (( UNIOPT_SEEN[$item] == 0 || UNIOPT_SEEN[$j] == 0 )) || { uniopt__fail "${UNIOPT_ITEM_IDS[$item]} conflicts with ${UNIOPT_ITEM_IDS[$j]}"; return; }
        ;;
    esac
    c=$((c + 1))
  done
}

uniopt_get() {
  local id="$1" out="${2-}" item
  uniopt__find_id "$id" || { uniopt__fail "unknown ID: $id"; return; }; item="$UNIOPT_FOUND_INDEX"
  [[ "${UNIOPT_REPEATABLE[$item]}" != 1 ]] || { uniopt__fail "$id is an array; use uniopt_get_all"; return; }
  if [[ -n "$out" ]]; then uniopt__valid_dest "$out" || { uniopt__fail "invalid output variable: $out"; return; }; printf -v "$out" '%s' "${UNIOPT_VALUE[$item]}"; else printf '%s\n' "${UNIOPT_VALUE[$item]}"; fi
}

uniopt_get_source() {
  uniopt__find_id "$1" || { uniopt__fail "unknown ID: $1"; return; }
  printf '%s\n' "${UNIOPT_SOURCE[$UNIOPT_FOUND_INDEX]}"
}

uniopt_get_all() {
  local id="$1" item i=0 out=0
  uniopt__find_id "$id" || { uniopt__fail "unknown ID: $id"; return; }; item="$UNIOPT_FOUND_INDEX"
  [[ "${UNIOPT_REPEATABLE[$item]}" == 1 ]] || { uniopt__fail "$id is not an array"; return; }
  UNIOPT_RESULT=()
  while (( i < ${#UNIOPT_MULTI_ITEM[@]} )); do
    if [[ "${UNIOPT_MULTI_ITEM[$i]}" == "$item" ]]; then UNIOPT_RESULT[$out]="${UNIOPT_MULTI_VALUE[$i]}"; out=$((out + 1)); fi
    i=$((i + 1))
  done
}

uniopt_get_unknown() {
  local i=0
  UNIOPT_RESULT=()
  while (( i < ${#UNIOPT_UNKNOWN_VALUES[@]} )); do
    UNIOPT_RESULT[$i]="${UNIOPT_UNKNOWN_VALUES[$i]}"
    i=$((i + 1))
  done
}
uniopt_value() { uniopt_get "$@"; }
uniopt_provenance() { uniopt_get_source "$@"; }
uniopt_values() {
  (( $# == 1 )) || { uniopt__fail "uniopt_values now takes one ID; read UNIOPT_RESULT or use uniopt_get_all"; return; }
  uniopt_get_all "$1"
}

uniopt__label() {
  local item="$1" label="" metavar="${UNIOPT_METAVAR[$1]}"
  [[ -n "$metavar" ]] || metavar=VALUE
  [[ -z "${UNIOPT_SHORT[$item]}" ]] || label="${UNIOPT_SHORT[$item]}"
  [[ -z "${UNIOPT_LONG[$item]}" ]] || label+="${label:+, }${UNIOPT_LONG[$item]}"
  [[ -z "${UNIOPT_NEG_LONG[$item]}" ]] || label+="${label:+, }${UNIOPT_NEG_LONG[$item]}"
  if uniopt__takes_value "$item"; then label+=" $metavar"; fi
  printf '%s' "$label"
}

uniopt__upper_id() { printf '%s' "$1" | LC_ALL=C tr 'a-z' 'A-Z'; }

uniopt_help() {
  local i=0 label width=0 suffix metavar have_positionals=0
  printf 'Usage: %s' "$UNIOPT_SCHEMA_NAME"
  while (( i < UNIOPT_ITEMS_COUNT )); do
    metavar="${UNIOPT_METAVAR[$i]}"; [[ -n "$metavar" ]] || metavar="$(uniopt__upper_id "${UNIOPT_ITEM_IDS[$i]}")"
    case "${UNIOPT_KIND[$i]}" in positional) printf ' %s' "$metavar" ;; remainder) printf ' [-- %s...]' "$metavar" ;; esac; i=$((i + 1))
  done
  printf '\n'; [[ -z "$UNIOPT_SCHEMA_SUMMARY" ]] || printf '\n%s\n' "$UNIOPT_SCHEMA_SUMMARY"; printf '\nOptions:\n'
  i=0; while (( i < UNIOPT_ITEMS_COUNT )); do
    if [[ ( "${UNIOPT_KIND[$i]}" == option || "${UNIOPT_KIND[$i]}" == alias ) && "${UNIOPT_INTERNAL[$i]}" != 1 ]]; then label="$(uniopt__label "$i")"; (( ${#label} > width )) && width=${#label}; fi
    i=$((i + 1))
  done
  i=0; while (( i < UNIOPT_ITEMS_COUNT )); do
    if [[ ( "${UNIOPT_KIND[$i]}" == option || "${UNIOPT_KIND[$i]}" == alias ) && "${UNIOPT_INTERNAL[$i]}" != 1 ]]; then
      label="$(uniopt__label "$i")"; suffix=""
      if [[ "${UNIOPT_HAS_DEFAULT[$i]}" == 1 ]]; then suffix=" (default: ${UNIOPT_DEFAULT[$i]})"; elif [[ -n "${UNIOPT_DEFAULT_ENV[$i]}" ]]; then suffix=" (default: environment)"; elif [[ -n "${UNIOPT_DEFAULT_FN[$i]}" ]]; then suffix=" (default: dynamic)"; fi
      [[ "${UNIOPT_REPEATABLE[$i]}" == 1 ]] && suffix+=" (repeatable)"; printf '  %-*s  %s%s\n' "$width" "$label" "${UNIOPT_HELP[$i]}" "$suffix"
    fi; i=$((i + 1))
  done
  i=0; while (( i < UNIOPT_ITEMS_COUNT )); do [[ "${UNIOPT_KIND[$i]}" == positional || "${UNIOPT_KIND[$i]}" == remainder ]] && have_positionals=1; i=$((i + 1)); done
  if (( have_positionals )); then printf '\nArguments:\n'; i=0; while (( i < UNIOPT_ITEMS_COUNT )); do if [[ "${UNIOPT_KIND[$i]}" == positional || "${UNIOPT_KIND[$i]}" == remainder ]]; then metavar="${UNIOPT_METAVAR[$i]}"; [[ -n "$metavar" ]] || metavar="$(uniopt__upper_id "${UNIOPT_ITEM_IDS[$i]}")"; printf '  %-*s  %s\n' "$width" "$metavar" "${UNIOPT_HELP[$i]}"; fi; i=$((i + 1)); done; fi
}

uniopt_markdown() {
  local i=0 j label default have_arguments=0 kind member target display_type
  printf '# `%s`\n\n' "$UNIOPT_SCHEMA_NAME"; [[ -z "$UNIOPT_SCHEMA_SUMMARY" ]] || printf '%s\n\n' "$UNIOPT_SCHEMA_SUMMARY"
  printf '## Options\n\n| Option | Type | Default | Description |\n|---|---|---|---|\n'
  while (( i < UNIOPT_ITEMS_COUNT )); do
    if [[ ( "${UNIOPT_KIND[$i]}" == option || "${UNIOPT_KIND[$i]}" == alias ) && "${UNIOPT_INTERNAL[$i]}" != 1 ]]; then
      label="$(uniopt__label "$i")"; default=""; [[ "${UNIOPT_HAS_DEFAULT[$i]}" == 1 ]] && default="${UNIOPT_DEFAULT[$i]}"; [[ -n "${UNIOPT_DEFAULT_ENV[$i]}" ]] && default="environment: ${UNIOPT_DEFAULT_ENV[$i]}"; [[ -n "${UNIOPT_DEFAULT_FN[$i]}" ]] && default="dynamic: ${UNIOPT_DEFAULT_FN[$i]}"
      display_type="${UNIOPT_TYPE[$i]}"; [[ "${UNIOPT_KIND[$i]}" == alias ]] && display_type=action
      printf '| `%s` | `%s` | `%s` | %s |\n' "$label" "$display_type" "$default" "${UNIOPT_HELP[$i]}"
    fi; i=$((i + 1))
  done
  i=0; while (( i < UNIOPT_ITEMS_COUNT )); do [[ "${UNIOPT_KIND[$i]}" == positional || "${UNIOPT_KIND[$i]}" == remainder ]] && have_arguments=1; i=$((i + 1)); done
  if (( have_arguments )); then
    printf '\n## Arguments\n\n| Argument | Type | Required | Description |\n|---|---|---|---|\n'
    i=0; while (( i < UNIOPT_ITEMS_COUNT )); do
      if [[ "${UNIOPT_KIND[$i]}" == positional || "${UNIOPT_KIND[$i]}" == remainder ]]; then
        label="${UNIOPT_METAVAR[$i]}"; [[ -n "$label" ]] || label="$(uniopt__upper_id "${UNIOPT_ITEM_IDS[$i]}")"; [[ "${UNIOPT_KIND[$i]}" == remainder ]] && label+="..."
        printf '| `%s` | `%s` | %s | %s |\n' "$label" "${UNIOPT_TYPE[$i]}" "$([[ "${UNIOPT_REQUIRED[$i]}" == 1 ]] && printf yes || printf no)" "${UNIOPT_HELP[$i]}"
      fi; i=$((i + 1))
    done
  fi
  if (( UNIOPT_CONSTRAINT_COUNT )); then
    printf '\n## Constraints\n\n'
    i=0; while (( i < UNIOPT_CONSTRAINT_COUNT )); do
      kind="${UNIOPT_CONSTRAINT_KIND[$i]}"; printf -- '- `%s`:' "$kind"; j=0
      while (( j < UNIOPT_CONSTRAINT_LENGTH[$i] )); do target="${UNIOPT_CONSTRAINT_MEMBER[$((UNIOPT_CONSTRAINT_START[$i] + j))]}"; member="${UNIOPT_ITEM_IDS[$target]}"; printf ' `%s`' "$member"; j=$((j + 1)); done
      printf '\n'; i=$((i + 1))
    done
  fi
}

uniopt__json_string() {
  local s="$1" out='"' c i=0 code
  local LC_ALL=C
  while (( i < ${#s} )); do c="${s:i:1}"; case "$c" in '"') out+='\"' ;; '\') out+='\\' ;; $'\b') out+='\b' ;; $'\f') out+='\f' ;; $'\n') out+='\n' ;; $'\r') out+='\r' ;; $'\t') out+='\t' ;; *) printf -v code '%d' "'$c"; if (( code < 32 )); then printf -v c '\\u%04x' "$code"; fi; out+="$c" ;; esac; i=$((i + 1)); done
  printf '%s"' "$out"
}

uniopt_json() {
  local i=0 j first=1 member_first target
  printf '{"schema_version":1,"command":'; uniopt__json_string "$UNIOPT_SCHEMA_NAME"; printf ',"summary":'; uniopt__json_string "$UNIOPT_SCHEMA_SUMMARY"; printf ',"unknown_policy":'; uniopt__json_string "$UNIOPT_UNKNOWN_POLICY"; printf ',"ui":{"confirm":'; uniopt__json_string "$UNIOPT_SCHEMA_UI_CONFIRM"; printf '},"items":['
  while (( i < UNIOPT_ITEMS_COUNT )); do
    (( first )) || printf ','; first=0; printf '{"id":'; uniopt__json_string "${UNIOPT_ITEM_IDS[$i]}"; printf ',"kind":'; uniopt__json_string "${UNIOPT_KIND[$i]}"; printf ',"type":'; uniopt__json_string "${UNIOPT_TYPE[$i]}"; printf ',"destination":'; uniopt__json_string "${UNIOPT_DEST[$i]}"; printf ',"short":'; uniopt__json_string "${UNIOPT_SHORT[$i]}"; printf ',"long":'; uniopt__json_string "${UNIOPT_LONG[$i]}"; printf ',"negative_long":'; uniopt__json_string "${UNIOPT_NEG_LONG[$i]}"; printf ',"metavar":'; uniopt__json_string "${UNIOPT_METAVAR[$i]}"; printf ',"help":'; uniopt__json_string "${UNIOPT_HELP[$i]}"
    printf ',"required":%s,"repeatable":%s,"internal":%s' "$([[ "${UNIOPT_REQUIRED[$i]}" == 1 ]] && printf true || printf false)" "$([[ "${UNIOPT_REPEATABLE[$i]}" == 1 ]] && printf true || printf false)" "$([[ "${UNIOPT_INTERNAL[$i]}" == 1 ]] && printf true || printf false)"
    printf ',"default":'; if [[ "${UNIOPT_HAS_DEFAULT[$i]}" == 1 ]]; then uniopt__json_string "${UNIOPT_DEFAULT[$i]}"; else printf null; fi; printf ',"dynamic_default":'; if [[ -n "${UNIOPT_DEFAULT_FN[$i]}" ]]; then uniopt__json_string "${UNIOPT_DEFAULT_FN[$i]}"; else printf null; fi; printf ',"environment_default":'; if [[ -n "${UNIOPT_DEFAULT_ENV[$i]}" ]]; then uniopt__json_string "${UNIOPT_DEFAULT_ENV[$i]}"; else printf null; fi; printf ',"store_constant":'; if [[ "${UNIOPT_HAS_STORE_CONST[$i]}" == 1 ]]; then uniopt__json_string "${UNIOPT_STORE_CONST[$i]}"; else printf null; fi
    printf ',"ui":{"label":'; uniopt__json_string "${UNIOPT_UI_LABEL[$i]}"; printf ',"group":'; uniopt__json_string "${UNIOPT_UI_GROUP[$i]}"; printf ',"control":'; uniopt__json_string "${UNIOPT_UI_CONTROL[$i]}"; printf ',"placeholder":'; uniopt__json_string "${UNIOPT_UI_PLACEHOLDER[$i]}"; printf ',"advanced":%s,"order":' "$([[ "${UNIOPT_UI_ADVANCED[$i]}" == 1 ]] && printf true || printf false)"; if [[ -n "${UNIOPT_UI_ORDER[$i]}" ]]; then printf '%s' "${UNIOPT_UI_ORDER[$i]}"; else printf null; fi; printf ',"min":'; if [[ -n "${UNIOPT_UI_MIN[$i]}" ]]; then uniopt__json_string "${UNIOPT_UI_MIN[$i]}"; else printf null; fi; printf ',"max":'; if [[ -n "${UNIOPT_UI_MAX[$i]}" ]]; then uniopt__json_string "${UNIOPT_UI_MAX[$i]}"; else printf null; fi; printf ',"step":'; if [[ -n "${UNIOPT_UI_STEP[$i]}" ]]; then uniopt__json_string "${UNIOPT_UI_STEP[$i]}"; else printf null; fi; printf ',"file_mode":'; uniopt__json_string "${UNIOPT_UI_FILE_MODE[$i]}"; printf '}'
    printf ',"choices":['; j=0; member_first=1; while (( j < UNIOPT_CHOICE_COUNT )); do if [[ "${UNIOPT_CHOICE_ITEM[$j]}" == "$i" ]]; then (( member_first )) || printf ','; member_first=0; uniopt__json_string "${UNIOPT_CHOICE_VALUE[$j]}"; fi; j=$((j + 1)); done; printf '],"sets":{'; j=0; member_first=1; while (( j < UNIOPT_SET_COUNT )); do if [[ "${UNIOPT_SET_ACTION[$j]}" == "$i" ]]; then (( member_first )) || printf ','; member_first=0; target="${UNIOPT_SET_TARGET[$j]}"; uniopt__json_string "${UNIOPT_ITEM_IDS[$target]}"; printf ':'; uniopt__json_string "${UNIOPT_SET_VALUE[$j]}"; fi; j=$((j + 1)); done; printf '}}'; i=$((i + 1))
  done
  printf '],"constraints":['; i=0; first=1; while (( i < UNIOPT_CONSTRAINT_COUNT )); do (( first )) || printf ','; first=0; printf '{"kind":'; uniopt__json_string "${UNIOPT_CONSTRAINT_KIND[$i]}"; printf ',"members":['; j=0; member_first=1; while (( j < UNIOPT_CONSTRAINT_LENGTH[$i] )); do (( member_first )) || printf ','; member_first=0; target="${UNIOPT_CONSTRAINT_MEMBER[$((UNIOPT_CONSTRAINT_START[$i] + j))]}"; uniopt__json_string "${UNIOPT_ITEM_IDS[$target]}"; j=$((j + 1)); done; printf ']}'; i=$((i + 1)); done; printf ']}\n'
}

uniopt_completion() {
  local command="${1:-$UNIOPT_SCHEMA_NAME}" function="${2:-_uniopt_${UNIOPT_SCHEMA_NAME//-/_}}" i=0 j pattern words spellings=""
  [[ "$function" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || { uniopt__fail "invalid completion function name: $function"; return; }
  while (( i < UNIOPT_ITEMS_COUNT )); do if [[ "${UNIOPT_INTERNAL[$i]}" != 1 ]]; then [[ -z "${UNIOPT_SHORT[$i]}" ]] || spellings+=" ${UNIOPT_SHORT[$i]}"; [[ -z "${UNIOPT_LONG[$i]}" ]] || spellings+=" ${UNIOPT_LONG[$i]}"; [[ -z "${UNIOPT_NEG_LONG[$i]}" ]] || spellings+=" ${UNIOPT_NEG_LONG[$i]}"; fi; i=$((i + 1)); done
  printf '%s() {\n' "$function"; printf '  local cur prev\n  cur=${COMP_WORDS[COMP_CWORD]}\n  prev=${COMP_WORDS[COMP_CWORD-1]}\n  case "$prev" in\n'
  i=0; while (( i < UNIOPT_ITEMS_COUNT )); do
    if [[ "${UNIOPT_INTERNAL[$i]}" != 1 && "${UNIOPT_KIND[$i]}" == option && ( "${UNIOPT_TYPE[$i]}" == enum || "${UNIOPT_TYPE[$i]}" == path ) ]]; then
      pattern=""; [[ -z "${UNIOPT_SHORT[$i]}" ]] || pattern="${UNIOPT_SHORT[$i]}"; [[ -z "${UNIOPT_LONG[$i]}" ]] || pattern+="${pattern:+|}${UNIOPT_LONG[$i]}"
      if [[ "${UNIOPT_TYPE[$i]}" == path ]]; then printf '    %s) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;\n' "$pattern"; else words=""; j=0; while (( j < UNIOPT_CHOICE_COUNT )); do [[ "${UNIOPT_CHOICE_ITEM[$j]}" == "$i" ]] && words+="${words:+ }${UNIOPT_CHOICE_VALUE[$j]}"; j=$((j + 1)); done; printf '    %s) COMPREPLY=( $(compgen -W %q -- "$cur") ); return ;;\n' "$pattern" "$words"; fi
    fi; i=$((i + 1))
  done
  printf '  esac\n  if [[ "$cur" == -* ]]; then COMPREPLY=( $(compgen -W %q -- "$cur") ); fi\n}\n' "$spellings"; printf 'complete -F %s %q\n' "$function" "$command"
}

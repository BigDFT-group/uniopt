_uniopt_dockerfile_to_wise_sdk() {
  local cur prev
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}
  case "$prev" in
    --output-dir) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
  esac
  if [[ "$cur" == -* ]]; then COMPREPLY=( $(compgen -W \ -h\ --help\ --gui\ --output-dir\ --script-name\ --env-name\ --warnings-name -- "$cur") ); fi
}
complete -F _uniopt_dockerfile_to_wise_sdk dockerfile-to-wise-sdk

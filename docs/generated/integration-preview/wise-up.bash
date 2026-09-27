_uniopt_wise_up() {
  local cur prev
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}
  case "$prev" in
    --env-file) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
    --extra-compose) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
  esac
  if [[ "$cur" == -* ]]; then COMPREPLY=( $(compgen -W \ -h\ --help\ --gui\ --env-file\ --name\ --extra-compose\ --build\ --replace\ --no-check\ --host-open\ --no-xhost-auth -- "$cur") ); fi
}
complete -F _uniopt_wise_up wise-up

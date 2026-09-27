_uniopt_wise_host_open() {
  local cur prev
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}
  case "$prev" in
    --env-file) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
    --socket) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
    --client-file) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
  esac
  if [[ "$cur" == -* ]]; then COMPREPLY=( $(compgen -W \ -h\ --help\ --gui\ --env-file\ --name\ --socket\ --open-command\ --once\ --test-mode\ --daemon\ --stop\ --client\ --client-file -- "$cur") ); fi
}
complete -F _uniopt_wise_host_open wise-host-open

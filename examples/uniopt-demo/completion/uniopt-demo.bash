_uniopt_uniopt_demo() {
  local cur prev
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}
  case "$prev" in
    -s|--style) COMPREPLY=( $(compgen -W friendly\ formal\ terse -- "$cur") ); return ;;
    -o|--output) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
  esac
  if [[ "$cur" == -* ]]; then COMPREPLY=( $(compgen -W \ -h\ --help\ --gui\ -n\ --name\ -s\ --style\ -o\ --output\ --loud\ --color\ --no-color\ -j\ --jobs\ -t\ --tag\ --show-sources\ --quick -- "$cur") ); fi
}
complete -F _uniopt_uniopt_demo uniopt-demo

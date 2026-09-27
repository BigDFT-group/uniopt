_uniopt_bigdftmk() {
  local cur prev
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}
  case "$prev" in
    -d|--homedir) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
    -s|--sources) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
    -b|--binaries) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
    -t|--target) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
  esac
  if [[ "$cur" == -* ]]; then COMPREPLY=( $(compgen -W \ -h\ --help\ --gui\ -X\ --display\ -w\ --workdir\ -k\ --keep\ -r\ --root\ -x\ --extra-cmd\ -e\ --extra-positional\ -d\ --homedir\ -g\ --gpus\ -s\ --sources\ -i\ --image\ -b\ --binaries\ -t\ --target\ -p\ --port -- "$cur") ); fi
}
complete -F _uniopt_bigdftmk bigdftmk

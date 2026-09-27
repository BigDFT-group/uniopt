_uniopt_wise_env() {
  local cur prev
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}
  case "$prev" in
    --env-file) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
    --base-env) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
    --workdir) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
    --workspace-path) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
    --platform) COMPREPLY=( $(compgen -W auto\ linux\ wsl -- "$cur") ); return ;;
    --container-mode) COMPREPLY=( $(compgen -W none\ sidecar -- "$cur") ); return ;;
    --sidecar-network) COMPREPLY=( $(compgen -W bridge\ host -- "$cur") ); return ;;
    --session-home) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
    --host-tmp) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
    --startup-script) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
  esac
  if [[ "$cur" == -* ]]; then COMPREPLY=( $(compgen -W \ -h\ --help\ --gui\ --env-file\ --name\ --base-env\ --workdir\ --workspace-path\ --platform\ --gpu\ --container-mode\ --inner-containers\ --docker-data-volume\ --sidecar-network\ --network-subnet\ --network-ipv6-subnet\ --no-ipv6\ --openvscode-port\ --publish\ --hostname\ --session-home\ --host-tmp\ --host-gitconfig\ --no-host-gitconfig\ --startup-script\ --xhost-localuser\ --host-open\ --no-host-open -- "$cur") ); fi
}
complete -F _uniopt_wise_env wise-env

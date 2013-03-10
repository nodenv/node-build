_node-build() {
  COMPREPLY=()
  local word="${COMP_WORDS[COMP_CWORD]}"

  if [ "$COMP_CWORD" -eq 1 ]; then
    COMPREPLY=( $(compgen -W "$(node-build commands)" -- "$word") )
  else
    local command="${COMP_WORDS[1]}"
    local completions="$(node-build completions "$command")"
    COMPREPLY=( $(compgen -W "$completions" -- "$word") )
  fi
}

complete -F _node-build node-build

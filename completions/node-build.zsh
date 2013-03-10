if [[ ! -o interactive ]]; then
    return
fi

compctl -K _node-build node-build

_node-build() {
  local word words completions
  read -cA words
  word="${words[2]}"

  if [ "${#words}" -eq 2 ]; then
    completions="$(node-build commands)"
  else
    completions="$(node-build completions "${word}")"
  fi

  reply=("${(ps:\n:)completions}")
}

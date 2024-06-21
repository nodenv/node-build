# shellcheck shell=bash

BATS_TMPDIR="$BATS_TEST_DIRNAME/tmp"
export TMP="$BATS_TMPDIR"/node-build-test
export NODE_BUILD_CURL_OPTS=
export NODE_BUILD_HTTP_CLIENT="curl"
export NODE_BUILD_TESTING=true

load ../node_modules/bats-support/load
load ../node_modules/bats-assert/load
load ../node_modules/bats-mock/stub

if [ "$FIXTURE_ROOT" != "$BATS_TEST_DIRNAME/fixtures" ]; then
  export FIXTURE_ROOT="$BATS_TEST_DIRNAME/fixtures"
  export INSTALL_ROOT="$BATS_TMPDIR/install"
  PATH="/usr/bin:/bin:/usr/sbin:/sbin"
  if [ "FreeBSD" = "$(uname -s)" ]; then
    PATH="/usr/local/bin:$PATH"
  fi
  PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
  PATH="$BATS_MOCK_BINDIR:$PATH"
  PATH="$BATS_TMPDIR/bin:$PATH"
  export PATH
fi

remove_commands_from_path() {
  local path cmd
  local NEWPATH=":$PATH:"
  while PATH="${NEWPATH#:}" command -v "$@" >/dev/null; do
    local paths=( $(PATH="${NEWPATH#:}" command -v "$@" | sed 's!/[^/]*$!!' | sort -u) )
    for path in "${paths[@]}"; do
      local tmp_path="$(mktemp -d "$TMP/path.XXXXX")"
      ln -fs "$path"/* "$tmp_path/"
      for cmd; do rm -f "$tmp_path/$cmd"; done
      NEWPATH="${NEWPATH/:$path:/:$tmp_path:}"
    done
  done
  echo "${NEWPATH#:}"
}

teardown() {
  # rm -fr "${BATS_TMPDIR:?}"/*
  rm -fr "${TMP:?}"
}

stub_repeated() {
  local program="$1"
  # shellcheck disable=SC2155
  local prefix="$(echo "$program" | tr a-z- A-Z_)"
  export "${prefix}_STUB_NOINDEX"=1
  stub "$@"
}

# Expose this for stub scripts.
inspect_args() {
  local arg
  local sep=''
  for arg; do
    if [[ $arg == *' '* ]]; then
      printf '%s"%s"' "$sep" "${arg//\"/\\\"}"
    elif [[ $arg == *'"'* ]]; then
      printf "%s'%s'" "$sep" "$arg"
    else
      printf '%s%s' "$sep" "$arg"
    fi
    sep=" "
  done
}
export -f inspect_args

run_inline_definition() {
  local definition="${BATS_TMPDIR}/build-definition"
  cat > "$definition"
  run node-build "$definition" "${1:-$INSTALL_ROOT}"
}

install_fixture() {
  local args=()

  while [ "${1#-}" != "$1" ]; do
    args+=("$1")
    shift 1
  done

  local name="$1"
  local destination="$2"
  [ -n "$destination" ] || destination="$INSTALL_ROOT"

  run node-build "${args[@]}" "$FIXTURE_ROOT/$name" "$destination"
}

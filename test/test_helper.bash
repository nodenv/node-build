# shellcheck shell=bash

BATS_TMPDIR="$BATS_TEST_DIRNAME/tmp"
export NODE_BUILD_CURL_OPTS=
export NODE_BUILD_HTTP_CLIENT="curl"

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
  local paths=( $(command -v "$@" | sed 's!/[^/]*$!!' | sort -u) )
  local NEWPATH=":$PATH:"
  for path in "${paths[@]}"; do
    local tmp_path="$(mktemp -d "$BATS_TMPDIR/path.XXXXX")"
    ln -fs "$path"/* "$tmp_path/"
    for cmd; do rm -f "$tmp_path/$cmd"; done
    NEWPATH="${NEWPATH/:$path:/:$tmp_path:}"
  done
  echo "${NEWPATH#:}"
}

teardown() {
  rm -fr "${BATS_TMPDIR:?}"/*
}

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

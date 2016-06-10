BATS_TMPDIR="$BATS_TEST_DIRNAME/tmp"

load ../node_modules/bats-assert/all
load ../node_modules/bats-mock/stub

if [ "$FIXTURE_ROOT" != "$BATS_TEST_DIRNAME/fixtures" ]; then
  export FIXTURE_ROOT="$BATS_TEST_DIRNAME/fixtures"
  export INSTALL_ROOT="$BATS_TMPDIR/install"
  PATH=/usr/bin:/usr/sbin:/bin/:/sbin
  PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
  PATH="$BATS_MOCK_BINDIR:$PATH"
  export PATH
fi

remove_command_from_path() {
  OLDIFS="${IFS}"
  local cmd="$1"
  local path
  local paths=()
  IFS=:
  for path in ${PATH}; do
    if [ -e "${path}/${cmd}" ]; then
      local tmp_path="$(mktemp -d "${TMP}/path.XXXXX")"
      ln -fs "${path}"/* "${tmp_path}"
      rm -f "${tmp_path}/${cmd}"
      paths["${#paths[@]}"]="${tmp_path}"
    else
      paths["${#paths[@]}"]="${path}"
    fi
  done
  export PATH="${paths[*]}"
  IFS="${OLDIFS}"
}

ensure_not_found_in_path() {
  local cmd
  for cmd; do
    if command -v "${cmd}" 1>/dev/null 2>&1; then
      remove_command_from_path "${cmd}"
    fi
  done
}

setup() {
  ensure_not_found_in_path aria2c
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
  local args

  while [ "${1#-}" != "$1" ]; do
    args="$args $1"
    shift 1
  done

  local name="$1"
  local destination="$2"
  [ -n "$destination" ] || destination="$INSTALL_ROOT"

  run node-build $args "$FIXTURE_ROOT/$name" "$destination"
}

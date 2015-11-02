BATS_TMPDIR="$BATS_TEST_DIRNAME/tmp"

load helpers/assertions/all
load helpers/mocks/stub

if [ "$FIXTURE_ROOT" != "$BATS_TEST_DIRNAME/fixtures" ]; then
  export FIXTURE_ROOT="$BATS_TEST_DIRNAME/fixtures"
  export INSTALL_ROOT="$BATS_TMPDIR/install"
  PATH=/usr/bin:/usr/sbin:/bin/:/sbin
  PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
  PATH="$BATS_MOCK_BINDIR:$PATH"
  export PATH
fi

teardown() {
  rm -fr "$BATS_TMPDIR"/*
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

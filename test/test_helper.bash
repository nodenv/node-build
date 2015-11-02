export TMP="$BATS_TEST_DIRNAME/tmp"

BATS_TMPDIR="$TMP"
load helpers/stub/stub

if [ "$FIXTURE_ROOT" != "$BATS_TEST_DIRNAME/fixtures" ]; then
  export FIXTURE_ROOT="$BATS_TEST_DIRNAME/fixtures"
  export INSTALL_ROOT="$TMP/install"
  PATH=/usr/bin:/usr/sbin:/bin/:/sbin
  PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
  PATH="$BATS_MOCK_BINDIR:$PATH"
  export PATH
fi

teardown() {
  rm -fr "$TMP"/*
}

run_inline_definition() {
  local definition="${TMP}/build-definition"
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

assert() {
  if ! "$@"; then
    flunk "failed: $@"
  fi
}

flunk() {
  { if [ "$#" -eq 0 ]; then cat -
    else echo "$@"
    fi
  } | sed "s:${TMP}:\${TMP}:g" >&2
  return 1
}

assert_success() {
  if [ "$status" -ne 0 ]; then
    { echo "command failed with exit status $status"
      echo "output: $output"
    } | flunk
  elif [ "$#" -gt 0 ]; then
    assert_output "$1"
  fi
}

assert_failure() {
  if [ "$status" -eq 0 ]; then
    flunk "expected failed exit status"
  elif [ "$#" -gt 0 ]; then
    assert_output "$1"
  fi
}

assert_equal() {
  if [ "$1" != "$2" ]; then
    { echo "expected: $1"
      echo "actual:   $2"
    } | flunk
  fi
}

assert_output() {
  local expected
  if [ $# -eq 0 ]; then expected="$(cat -)"
  else expected="$1"
  fi
  assert_equal "$expected" "$output"
}

assert_output_contains() {
  local expected="$1"
  if [ -z "$expected" ]; then
    echo "assert_output_contains needs an argument" >&2
    return 1
  fi
  echo "$output" | $(type -p ggrep grep | head -1) -F "$expected" >/dev/null || {
    { echo "expected output to contain $expected"
      echo "actual: $output"
    } | flunk
  }
}

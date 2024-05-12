#!/usr/bin/env bats

load test_helper
NUM_DEFINITIONS="$(ls "$BATS_TEST_DIRNAME"/../share/node-build | wc -l)"

@test "list all local definitions" {
  run node-build --definitions
  assert_success
  assert_output --partial "0.10.40"
  assert_output --partial "iojs-3.3.1"
  assert [ "${#lines[*]}" -eq "$NUM_DEFINITIONS" ]
}

@test "custom NODE_BUILD_ROOT: nonexistent" {
  export NODE_BUILD_ROOT="$BATS_TMPDIR"
  refute [ -e "${NODE_BUILD_ROOT}/share/node-build" ]
  run node-build --definitions
  assert_success
  refute_output
}

@test "custom NODE_BUILD_ROOT: single definition" {
  export NODE_BUILD_ROOT="$BATS_TMPDIR"
  mkdir -p "${NODE_BUILD_ROOT}/share/node-build"
  touch "${NODE_BUILD_ROOT}/share/node-build/4.2.1-test"
  run node-build --definitions
  assert_success
  assert_output "4.2.1-test"
}

@test "one path via NODE_BUILD_DEFINITIONS" {
  export NODE_BUILD_DEFINITIONS="${BATS_TMPDIR}/definitions"
  mkdir -p "$NODE_BUILD_DEFINITIONS"
  touch "${NODE_BUILD_DEFINITIONS}/4.2.1-test"
  run node-build --definitions
  assert_success
  assert_output --partial "4.2.1-test"
  assert [ "${#lines[*]}" -eq "$((NUM_DEFINITIONS + 1))" ]
}

@test "multiple paths via NODE_BUILD_DEFINITIONS" {
  export NODE_BUILD_DEFINITIONS="${BATS_TMPDIR}/definitions:${BATS_TMPDIR}/other"
  mkdir -p "${BATS_TMPDIR}/definitions"
  touch "${BATS_TMPDIR}/definitions/4.2.1-test"
  mkdir -p "${BATS_TMPDIR}/other"
  touch "${BATS_TMPDIR}/other/4.0.0-test"
  run node-build --definitions
  assert_success
  assert_output --partial "4.2.1-test"
  assert_output --partial "4.0.0-test"
  assert [ "${#lines[*]}" -eq "$((NUM_DEFINITIONS + 2))" ]
}

@test "installing definition from NODE_BUILD_DEFINITIONS by priority" {
  export NODE_BUILD_DEFINITIONS="${BATS_TMPDIR}/definitions:${BATS_TMPDIR}/other"
  mkdir -p "${BATS_TMPDIR}/definitions"
  echo true > "${BATS_TMPDIR}/definitions/4.2.1-test"
  mkdir -p "${BATS_TMPDIR}/other"
  echo false > "${BATS_TMPDIR}/other/4.2.1-test"
  run bin/node-build "4.2.1-test" "${BATS_TMPDIR}/install"
  assert_success
  refute_output
}

@test "installing nonexistent definition" {
  run node-build "nonexistent" "${BATS_TMPDIR}/install"
  assert [ "$status" -eq 2 ]
  assert_output "node-build: definition not found: nonexistent"
}

@test "sorting Node versions" {
  export NODE_BUILD_ROOT="$BATS_TMPDIR"
  mkdir -p "${NODE_BUILD_ROOT}/share/node-build"
  expected="0.8.9
0.10.40
4.0.0
4.2.3
4.11.1
10.0.0
iojs-0.12.0-dev
iojs-1.0.0
iojs-1.x-dev
iojs-3.3.1"
  for ver in $expected; do
    touch "${NODE_BUILD_ROOT}/share/node-build/$ver"
  done
  run node-build --definitions
  assert_success
  assert_output "$expected"
}

@test "filtering previous Node versions" {
  export NODE_BUILD_ROOT="$BATS_TMPDIR"
  mkdir -p "${NODE_BUILD_ROOT}/share/node-build"

  all_versions="
2.4.0
2.4.1
2.4.2
2.4.3
2.4.4
2.4.5
2.4.6
2.4.7
2.4.8
2.4.9
2.5.0
2.5.1
2.5.2
2.5.3
2.5.4
2.5.5
2.5.6
2.5.7
2.6.0
2.6.1
2.6.2
2.6.3
2.6.4
2.6.5
2.7.0
jruby-1.5.6
jruby-9.2.7.0
jruby-9.2.8.0
jruby-9.2.9.0
maglev-1.0.0
mruby-1.4.1
mruby-2.0.0
mruby-2.0.1
mruby-2.1.0
rbx-3.104
rbx-3.105
rbx-3.106
rbx-3.107
truffleruby-19.2.0.1
truffleruby-19.3.0
truffleruby-19.3.0.2
truffleruby-19.3.1"

  expected="2.4.9
2.5.7
2.6.5
2.7.0
jruby-9.2.9.0
maglev-1.0.0
mruby-2.1.0
rbx-3.107
truffleruby-19.3.1"

  for ver in $all_versions; do
    touch "${NODE_BUILD_ROOT}/share/node-build/$ver"
  done
  run node-build --list
  assert_success
  assert_output "$expected"
}

@test "removing duplicate Node versions" {
  export NODE_BUILD_ROOT="$BATS_TMPDIR"
  export NODE_BUILD_DEFINITIONS="${NODE_BUILD_ROOT}/share/node-build"
  mkdir -p "$NODE_BUILD_DEFINITIONS"
  touch "${NODE_BUILD_DEFINITIONS}/0.10.3"
  touch "${NODE_BUILD_DEFINITIONS}/4.2.0"

  run node-build --definitions
  assert_success
  assert_output - <<OUT
0.10.3
4.2.0
OUT
}

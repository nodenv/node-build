#!/usr/bin/env bats

load test_helper
NUM_DEFINITIONS="$(ls "$BATS_TEST_DIRNAME"/../share/node-build | wc -l)"

@test "list built-in definitions" {
  run node-build --definitions
  assert_success
  assert_output_contains "0.10.40"
  assert_output_contains "iojs-3.3.1"
  assert [ "${#lines[*]}" -eq "$NUM_DEFINITIONS" ]
}

@test "custom NODE_BUILD_ROOT: nonexistent" {
  export NODE_BUILD_ROOT="$TMP"
  assert [ ! -e "${NODE_BUILD_ROOT}/share/node-build" ]
  run node-build --definitions
  assert_success ""
}

@test "custom NODE_BUILD_ROOT: single definition" {
  export NODE_BUILD_ROOT="$TMP"
  mkdir -p "${NODE_BUILD_ROOT}/share/node-build"
  touch "${NODE_BUILD_ROOT}/share/node-build/4.2.1-test"
  run node-build --definitions
  assert_success "4.2.1-test"
}

@test "one path via NODE_BUILD_DEFINITIONS" {
  export NODE_BUILD_DEFINITIONS="${TMP}/definitions"
  mkdir -p "$NODE_BUILD_DEFINITIONS"
  touch "${NODE_BUILD_DEFINITIONS}/4.2.1-test"
  run node-build --definitions
  assert_success
  assert_output_contains "4.2.1-test"
  assert [ "${#lines[*]}" -eq "$((NUM_DEFINITIONS + 1))" ]
}

@test "multiple paths via NODE_BUILD_DEFINITIONS" {
  export NODE_BUILD_DEFINITIONS="${TMP}/definitions:${TMP}/other"
  mkdir -p "${TMP}/definitions"
  touch "${TMP}/definitions/4.2.1-test"
  mkdir -p "${TMP}/other"
  touch "${TMP}/other/4.0.0-test"
  run node-build --definitions
  assert_success
  assert_output_contains "4.2.1-test"
  assert_output_contains "4.0.0-test"
  assert [ "${#lines[*]}" -eq "$((NUM_DEFINITIONS + 2))" ]
}

@test "installing definition from NODE_BUILD_DEFINITIONS by priority" {
  export NODE_BUILD_DEFINITIONS="${TMP}/definitions:${TMP}/other"
  mkdir -p "${TMP}/definitions"
  echo true > "${TMP}/definitions/4.2.1-test"
  mkdir -p "${TMP}/other"
  echo false > "${TMP}/other/4.2.1-test"
  run bin/node-build "4.2.1-test" "${TMP}/install"
  assert_success ""
}

@test "installing nonexistent definition" {
  run node-build "nonexistent" "${TMP}/install"
  assert [ "$status" -eq 2 ]
  assert_output "node-build: definition not found: nonexistent"
}

@test "sorting Node versions" {
  export NODE_BUILD_ROOT="$TMP"
  mkdir -p "${NODE_BUILD_ROOT}/share/node-build"
  expected="0.8.9
0.10.40
4.0.0
iojs-0.12.0-dev
iojs-1.0.0
iojs-1.x-dev
iojs-3.3.1"
  for ver in "$expected"; do
    touch "${NODE_BUILD_ROOT}/share/node-build/$ver"
  done
  run node-build --definitions
  assert_success "$expected"
}

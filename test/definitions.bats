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

 eol_versions="17.0.0
17.9.1
19.0.0
19.9.0
21.0.0
21.7.3
graal+ce_java11-19.3.0
graal+ce_java11-19.3.0.2
graal+ce_java8-19.3.0
graal+ce_java8-19.3.0.2
graal+ce_java11-19.3.1
graal+ce_java8-19.3.1
iojs-1.0.0
iojs-1.8.4
iojs-2.0.0
iojs-2.5.0
iojs-3.0.0
iojs-3.3.1"

pre_versions="9.x-dev
chakracore-nightly
graal+ce-1.0.0-rc1
"

  all_versions=$eol_versions\
$pre_versions"
18.0.0
18.20.2
20.0.0
20.12.2
22.0.0
22.1.0
chakracore-8.1.2
chakracore-8.11.1
chakracore-10.0.0
chakracore-10.13.0
graal+ce-19.0.0
graal+ce-19.2.1
graal+ce_java11-19.3.0
graal+ce_java11-19.3.0.2
graal+ce_java8-19.3.0
graal+ce_java8-19.3.0.2
graal+ce_java11-19.3.1
graal+ce_java8-19.3.1
graal+ce_java11-20.0.0
graal+ce_java8-20.0.0"

  expected="18.20.2
20.12.2
22.1.0
chakracore-8.11.1
chakracore-10.13.0
graal+ce-19.2.1
graal+ce_java11-20.0.0
graal+ce_java8-20.0.0"

  for ver in $all_versions; do
    touch "${NODE_BUILD_ROOT}/share/node-build/$ver"
  done

  for eol in $eol_versions; do
    echo "warn_eol" >> "${NODE_BUILD_ROOT}/share/node-build/$eol"
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

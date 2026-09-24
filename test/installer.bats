#!/usr/bin/env bats

load test_helper

@test "installs node-build into PREFIX" {
  mkdir -p "$TMP"
  cd "$TMP"
  PREFIX="${PWD}/usr" run "${BATS_TEST_DIRNAME}/../install.sh"
  assert_success
  refute_output

  cd usr

  assert [ -x bin/node-build ]
  assert [ -x bin/nodenv-install ]
  assert [ -x bin/nodenv-uninstall ]

  assert [ -e share/node-build/0.10.36 ]
  assert [ -e share/node-build/iojs-1.0.0 ]
}

@test "build definitions don't have the executable bit" {
  mkdir -p "$TMP"
  cd "$TMP"
  PREFIX="${PWD}/usr" run "${BATS_TEST_DIRNAME}/../install.sh"
  assert_success
  refute_output

  run $BASH -c 'ls -l usr/share/node-build | tail -2 | cut -c1-10'
  assert_output - <<OUT
-rw-r--r--
-rw-r--r--
OUT
}

@test "overwrites old installation" {
  mkdir -p "$TMP"
  cd "$TMP"
  mkdir -p bin share/node-build
  touch bin/node-build
  touch share/node-build/0.10.36

  PREFIX="$PWD" run "${BATS_TEST_DIRNAME}/../install.sh"
  assert_success
  refute_output

  assert [ -x bin/node-build ]
  run grep "install_package" share/node-build/0.10.36
  assert_success
}

@test "unrelated files are untouched" {
  mkdir -p "$TMP"
  cd "$TMP"
  mkdir -p bin share/bananas
  chmod g-w bin
  touch bin/bananas
  touch share/bananas/docs

  PREFIX="$PWD" run "${BATS_TEST_DIRNAME}/../install.sh"
  assert_success
  refute_output

  assert [ -e bin/bananas ]
  assert [ -e share/bananas/docs ]

  run ls -ld bin
  assert_equal "r-x" "${output:4:3}"
}

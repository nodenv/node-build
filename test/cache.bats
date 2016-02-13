#!/usr/bin/env bats

load test_helper
export NODE_BUILD_CACHE_PATH="$BATS_TMPDIR/cache"

setup() {
  mkdir -p "$NODE_BUILD_CACHE_PATH"
}


@test "packages are saved to download cache" {
  stub aria2c "-o * http://example.com/* : cp $FIXTURE_ROOT/\${3##*/} \$2"

  install_fixture definitions/without-checksum

  assert_success
  assert [ -e "${NODE_BUILD_CACHE_PATH}/package-1.0.0.tar.gz" ]

  unstub aria2c
}


@test "cached package without checksum" {
  stub aria2c
  cp "${FIXTURE_ROOT}/package-1.0.0.tar.gz" "$NODE_BUILD_CACHE_PATH"

  install_fixture definitions/without-checksum

  assert_success
  assert [ -e "${NODE_BUILD_CACHE_PATH}/package-1.0.0.tar.gz" ]

  unstub aria2c
}


@test "cached package with valid checksum" {
  stub shasum true "echo ba988b1bb4250dee0b9dd3d4d722f9c64b2bacfc805d1b6eba7426bda72dd3c5"
  stub aria2c
  cp "${FIXTURE_ROOT}/package-1.0.0.tar.gz" "$NODE_BUILD_CACHE_PATH"

  install_fixture definitions/with-checksum

  assert_success
  assert [ -x "${INSTALL_ROOT}/bin/package" ]
  assert [ -e "${NODE_BUILD_CACHE_PATH}/package-1.0.0.tar.gz" ]

  unstub aria2c
  unstub shasum
}


@test "cached package with invalid checksum falls back to original URL and updates cache" {
  local checksum="ba988b1bb4250dee0b9dd3d4d722f9c64b2bacfc805d1b6eba7426bda72dd3c5"
  stub shasum true "echo invalid" "echo $checksum"
  stub aria2c "-o * http://example.com/* : cp $FIXTURE_ROOT/\${3##*/} \$2"

  touch "${NODE_BUILD_CACHE_PATH}/package-1.0.0.tar.gz"

  install_fixture definitions/with-checksum

  assert_success
  assert [ -x "${INSTALL_ROOT}/bin/package" ]
  assert [ -e "${NODE_BUILD_CACHE_PATH}/package-1.0.0.tar.gz" ]
  assert diff -q "${NODE_BUILD_CACHE_PATH}/package-1.0.0.tar.gz" "${FIXTURE_ROOT}/package-1.0.0.tar.gz"

  unstub aria2c
  unstub shasum
}


@test "nonexistent cache directory is ignored" {
  stub aria2c "-o * http://example.com/* : cp $FIXTURE_ROOT/\${3##*/} \$2"
  export NODE_BUILD_CACHE_PATH="${BATS_TMPDIR}/nonexistent"

  install_fixture definitions/without-checksum

  assert_success
  assert [ -x "${INSTALL_ROOT}/bin/package" ]
  refute [ -d "$NODE_BUILD_CACHE_PATH" ]

  unstub aria2c
}

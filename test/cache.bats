#!/usr/bin/env bats

load test_helper
export NODE_BUILD_SKIP_MIRROR=1
export NODE_BUILD_CACHE_PATH="$TMP/cache"

setup() {
  mkdir -p "$NODE_BUILD_CACHE_PATH"
}


@test "packages are saved to download cache" {
  stub sha1 true
  stub curl "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$3"

  install_fixture definitions/without-checksum
  [ "$status" -eq 0 ]
  [ -e "${NODE_BUILD_CACHE_PATH}/package-1.0.0.tar.gz" ]

  unstub curl
  unstub sha1
}


@test "cached package without checksum" {
  stub sha1 true
  stub curl

  cp "${FIXTURE_ROOT}/package-1.0.0.tar.gz" "$NODE_BUILD_CACHE_PATH"

  install_fixture definitions/without-checksum
  [ "$status" -eq 0 ]
  [ -e "${NODE_BUILD_CACHE_PATH}/package-1.0.0.tar.gz" ]

  unstub curl
  unstub sha1
}


@test "cached package with valid checksum" {
  stub sha1 true "echo c2dca7d96803baebcdc7eb831eaaca9963330627"
  stub curl

  cp "${FIXTURE_ROOT}/package-1.0.0.tar.gz" "$NODE_BUILD_CACHE_PATH"

  install_fixture definitions/with-checksum
  [ "$status" -eq 0 ]
  [ -x "${INSTALL_ROOT}/bin/package" ]
  [ -e "${NODE_BUILD_CACHE_PATH}/package-1.0.0.tar.gz" ]

  unstub curl
  unstub sha1
}


@test "cached package with invalid checksum falls back to mirror and updates cache" {
  export NODE_BUILD_SKIP_MIRROR=
  local checksum="c2dca7d96803baebcdc7eb831eaaca9963330627"

  stub sha1 true "echo invalid" "echo $checksum"
  stub curl "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/package-1.0.0.tar.gz \$3"

  touch "${NODE_BUILD_CACHE_PATH}/package-1.0.0.tar.gz"

  install_fixture definitions/with-checksum
  [ "$status" -eq 0 ]
  [ -x "${INSTALL_ROOT}/bin/package" ]
  [ -e "${NODE_BUILD_CACHE_PATH}/package-1.0.0.tar.gz" ]
  diff -q "${NODE_BUILD_CACHE_PATH}/package-1.0.0.tar.gz" "${FIXTURE_ROOT}/package-1.0.0.tar.gz"

  unstub curl
  unstub sha1
}


@test "nonexistent cache directory is ignored" {
  stub sha1 true
  stub curl "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$3"

  export NODE_BUILD_CACHE_PATH="${TMP}/nonexistent"

  install_fixture definitions/without-checksum
  [ "$status" -eq 0 ]
  [ -x "${INSTALL_ROOT}/bin/package" ]
  [ ! -d "$NODE_BUILD_CACHE_PATH" ]

  unstub curl
  unstub sha1
}

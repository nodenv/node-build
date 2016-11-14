#!/usr/bin/env bats

load test_helper
export NODE_BUILD_SKIP_MIRROR=
export NODE_BUILD_CACHE_PATH=
export NODE_BUILD_MIRROR_URL=http://mirror.example.com
export NODE_BUILD_CURL_OPTS=

setup() {
  ensure_not_found_in_path aria2c
}


@test "package URL without checksum bypasses mirror" {
  stub curl "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$3"

  install_fixture definitions/without-checksum
  echo "$output" >&2

  assert_success
  assert [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub curl
}


@test "package URL with checksum but no shasum support bypasses mirror" {
  stub shasum false
  stub curl "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$3"

  install_fixture definitions/with-checksum

  assert_success
  assert [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub curl
  unstub shasum
}


@test "package URL with checksum hits mirror first" {
  local checksum="ba988b1bb4250dee0b9dd3d4d722f9c64b2bacfc805d1b6eba7426bda72dd3c5"
  local mirror_url="${NODE_BUILD_MIRROR_URL}/$checksum"

  stub shasum true "echo $checksum"
  stub curl "-*I* $mirror_url : true" \
    "-q -o * -*S* $mirror_url : cp $FIXTURE_ROOT/package-1.0.0.tar.gz \$3"

  install_fixture definitions/with-checksum

  assert_success
  assert [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub curl
  unstub shasum
}


@test "package is fetched from original URL if mirror download fails" {
  local checksum="ba988b1bb4250dee0b9dd3d4d722f9c64b2bacfc805d1b6eba7426bda72dd3c5"
  local mirror_url="${NODE_BUILD_MIRROR_URL}/$checksum"

  stub shasum true "echo $checksum"
  stub curl "-*I* $mirror_url : false" \
    "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$3"

  install_fixture definitions/with-checksum

  assert_success
  assert [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub curl
  unstub shasum
}


@test "package is fetched from original URL if mirror download checksum is invalid" {
  local checksum="ba988b1bb4250dee0b9dd3d4d722f9c64b2bacfc805d1b6eba7426bda72dd3c5"
  local mirror_url="${NODE_BUILD_MIRROR_URL}/$checksum"

  stub shasum true "echo invalid" "echo $checksum"
  stub curl "-*I* $mirror_url : true" \
    "-q -o * -*S* $mirror_url : cp $FIXTURE_ROOT/package-1.0.0.tar.gz \$3" \
    "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$3"

  install_fixture definitions/with-checksum
  echo "$output" >&2

  assert_success
  assert [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub curl
  unstub shasum
}


@test "default mirror URL" {
  export NODE_BUILD_MIRROR_URL=
  local checksum="ba988b1bb4250dee0b9dd3d4d722f9c64b2bacfc805d1b6eba7426bda72dd3c5"

  stub shasum true "echo $checksum"
  stub curl "-*I* : true" \
    "-q -o * -*S* https://?*/$checksum : cp $FIXTURE_ROOT/package-1.0.0.tar.gz \$3" \

  install_fixture definitions/with-checksum

  assert_success
  assert [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub curl
  unstub shasum
}

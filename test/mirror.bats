#!/usr/bin/env bats

load test_helper
export NODE_BUILD_SKIP_MIRROR=
export NODE_BUILD_CACHE_PATH=
export NODE_BUILD_MIRROR_URL=http://mirror.example.com


@test "package URL without checksum bypasses mirror" {
  stub sha1 true
  stub curl "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$3"

  install_fixture definitions/without-checksum
  echo "$output" >&2
  [ "$status" -eq 0 ]
  [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub curl
  unstub sha1
}


@test "package URL with checksum but no SHA1 support bypasses mirror" {
  stub sha1 false
  stub curl "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$3"

  install_fixture definitions/with-checksum
  [ "$status" -eq 0 ]
  [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub curl
  unstub sha1
}


@test "package URL with checksum hits mirror first" {
  local checksum="c2dca7d96803baebcdc7eb831eaaca9963330627"
  local mirror_url="${NODE_BUILD_MIRROR_URL}/$checksum"

  stub sha1 true "echo $checksum"
  stub curl "-*I* $mirror_url : true" \
    "-q -o * -*S* $mirror_url : cp $FIXTURE_ROOT/package-1.0.0.tar.gz \$3"

  install_fixture definitions/with-checksum
  [ "$status" -eq 0 ]
  [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub curl
  unstub sha1
}


@test "package is fetched from original URL if mirror download fails" {
  local checksum="c2dca7d96803baebcdc7eb831eaaca9963330627"
  local mirror_url="${NODE_BUILD_MIRROR_URL}/$checksum"

  stub sha1 true "echo $checksum"
  stub curl "-*I* $mirror_url : false" \
    "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$3"

  install_fixture definitions/with-checksum
  [ "$status" -eq 0 ]
  [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub curl
  unstub sha1
}


@test "package is fetched from original URL if mirror download checksum is invalid" {
  local checksum="c2dca7d96803baebcdc7eb831eaaca9963330627"
  local mirror_url="${NODE_BUILD_MIRROR_URL}/$checksum"

  stub sha1 true "echo invalid" "echo $checksum"
  stub curl "-*I* $mirror_url : true" \
    "-q -o * -*S* $mirror_url : cp $FIXTURE_ROOT/package-1.0.0.tar.gz \$3" \
    "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$3"

  install_fixture definitions/with-checksum
  echo "$output" >&2
  [ "$status" -eq 0 ]
  [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub curl
  unstub sha1
}


@test "default mirror URL" {
  export NODE_BUILD_MIRROR_URL=
  local checksum="c2dca7d96803baebcdc7eb831eaaca9963330627"

  stub sha1 true "echo $checksum"
  stub curl "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/package-1.0.0.tar.gz \$3"

  install_fixture definitions/with-checksum
  [ "$status" -eq 0 ]
  [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub curl
  unstub sha1
}

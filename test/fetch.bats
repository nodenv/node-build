#!/usr/bin/env bats

load test_helper
export NODE_BUILD_SKIP_MIRROR=1
export NODE_BUILD_CACHE_PATH=

setup() {
  export NODE_BUILD_BUILD_PATH="${BATS_TMPDIR}/source"
  mkdir -p "${NODE_BUILD_BUILD_PATH}"
}

@test "failed download displays error message" {
  stub curl false

  install_fixture definitions/without-checksum
  assert_failure
  assert_output --partial "> http://example.com/packages/package-1.0.0.tar.gz"
  assert_output --partial "error: failed to download package-1.0.0.tar.gz"
}

@test "no download tool" {
  skip "This test fails on ubuntu-20 for some reason"
  export -n NODE_BUILD_HTTP_CLIENT
  clean_path="$(remove_commands_from_path curl wget aria2c)"

  PATH="$clean_path" install_fixture definitions/without-checksum
  assert_failure
  assert_output --partial 'error: install `curl`, `wget`, or `aria2c` to download packages'
}

@test "using aria2c if available" {
  export NODE_BUILD_ARIA2_OPTS=
  export -n NODE_BUILD_HTTP_CLIENT
  stub aria2c "--allow-overwrite=true --no-conf=true -o * http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$4"

  install_fixture definitions/without-checksum
  assert_success
  assert_output - <<OUT
Downloading package-1.0.0.tar.gz...
-> http://example.com/packages/package-1.0.0.tar.gz
Installing package-1.0.0...
Installed package-1.0.0 to ${BATS_TMPDIR}/install
OUT
  unstub aria2c
}

@test "fetching from git repository" {
  stub git "clone --depth 1 --branch main http://example.com/packages/package.git package-dev : mkdir package-dev"

  run_inline_definition <<DEF
install_git "package-dev" "http://example.com/packages/package.git" main copy
DEF
  assert_success
  assert_output - <<OUT
Cloning http://example.com/packages/package.git...
Installing package-dev...
Installed package-dev to ${BATS_TMPDIR}/install
OUT
  unstub git
}

@test "updating existing git repository" {
  mkdir -p "${NODE_BUILD_BUILD_PATH}/package-dev"
  stub git \
    "-C package-dev fetch --depth 1 origin +main : true" \
    "-C package-dev checkout -q -B main origin/main : true"

  run_inline_definition <<DEF
install_git "package-dev" "http://example.com/packages/package.git" main copy
DEF
  assert_success
  assert_output - <<OUT
Cloning http://example.com/packages/package.git...
Installing package-dev...
Installed package-dev to ${BATS_TMPDIR}/install
OUT
  unstub git
}

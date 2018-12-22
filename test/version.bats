#!/usr/bin/env bats

load test_helper

regex='"version":[ \t]*"([^"]*)"'
[[ $(cat "${BATS_TEST_DIRNAME}/../package.json") =~ $regex ]]
pkg_version=${BASH_REMATCH[1]}

@test "node-build static version" {
  stub git 'echo "ASPLODE" >&2; exit 1'
  run node-build --version
  assert_success
  assert_output "node-build ${pkg_version}"
  unstub git
}

@test "node-build git version" {
  stub git \
    'remote -v : echo origin https://github.com/nodenv/node-build.git' \
    "describe --tags HEAD : echo v1984-12-gSHA"
  run node-build --version
  assert_success
  assert_output "node-build 1984-12-gSHA"
  unstub git
}

@test "git describe fails" {
  stub git \
    'remote -v : echo origin https://github.com/nodenv/node-build.git' \
    "describe --tags HEAD : echo ASPLODE >&2; exit 1"
  run node-build --version
  assert_success
  assert_output "node-build ${pkg_version}"
  unstub git
}

@test "git remote doesn't match" {
  stub git \
    'remote -v : echo origin https://github.com/Homebrew/homebrew.git' \
    "describe --tags HEAD : echo v1984-12-gSHA"
  run node-build --version
  assert_success
  assert_output "node-build ${pkg_version}"
}

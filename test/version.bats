#!/usr/bin/env bats

load test_helper

pkg_version="$(egrep '"version":' ${BATS_TEST_DIRNAME}/../package.json | awk -v FS=': ' '{v=$2; gsub(/[",]/,"",v); print v}')"

@test "node-build static version" {
  stub git 'echo "ASPLODE" >&2; exit 1'
  run node-build --version
  assert_success "node-build ${pkg_version}"
  unstub git
}

@test "node-build git version" {
  stub git \
    'remote -v : echo origin https://github.com/sstephenson/node-build.git' \
    "describe --tags HEAD : echo v1984-12-gSHA"
  run node-build --version
  assert_success "node-build 1984-12-gSHA"
  unstub git
}

@test "git describe fails" {
  stub git \
    'remote -v : echo origin https://github.com/sstephenson/node-build.git' \
    "describe --tags HEAD : echo ASPLODE >&2; exit 1"
  run node-build --version
  assert_success "node-build ${pkg_version}"
  unstub git
}

@test "git remote doesn't match" {
  stub git \
    'remote -v : echo origin https://github.com/Homebrew/homebrew.git' \
    "describe --tags HEAD : echo v1984-12-gSHA"
  run node-build --version
  assert_success "node-build ${pkg_version}"
}

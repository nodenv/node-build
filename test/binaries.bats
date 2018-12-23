#!/usr/bin/env bats

load test_helper
export NODE_BUILD_CACHE_PATH=

setup() {
  stub uname '-s : echo Darwin' '-m : echo x86_64' '-s : echo Darwin'
  stub curl \
    "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$3"\
    "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$3"
}

@test "installs binary if platform-matching binary" {
  run_inline_definition <<DEF
binary darwin-x64 "http://example.com/packages/binary-1.0.0.tar.gz"
install_package "package-1.0.0" "http://example.com/packages/package-1.0.0.tar.gz" copy
DEF

  assert_success
  assert_output - <<OUT
Downloading binary-1.0.0.tar.gz...
-> http://example.com/packages/binary-1.0.0.tar.gz
Installing binary-1.0.0...
Installed binary-1.0.0 to ${BATS_TMPDIR}/install
OUT
  refute_line 'Installing package-1.0.0...'
}

@test "matches distro if os doesn't match" {
  stub lsb_release '-sir : echo 15.10 Ubuntu'
  run_inline_definition <<DEF
binary ubuntu-x64 "http://example.com/packages/binary-1.0.0.tar.gz"
install_package "package-1.0.0" "http://example.com/packages/package-1.0.0.tar.gz" copy
DEF

  assert_success
  assert_output - <<OUT
Downloading binary-1.0.0.tar.gz...
-> http://example.com/packages/binary-1.0.0.tar.gz
Installing binary-1.0.0...
Installed binary-1.0.0 to ${BATS_TMPDIR}/install
OUT
  refute_line 'Installing package-1.0.0...'
}

@test "installs first of multiple matching binaries" {
  run_inline_definition <<DEF
binary darwin-x64 "http://example.com/packages/binary-1.0.0.tar.gz"
binary darwin-x64 "http://example.com/packages/secondary-1.0.0.tar.gz"
install_package "package-1.0.0" "http://example.com/packages/package-1.0.0.tar.gz" copy
DEF

  assert_success
  assert_output - <<OUT
Downloading binary-1.0.0.tar.gz...
-> http://example.com/packages/binary-1.0.0.tar.gz
Installing binary-1.0.0...
Installed binary-1.0.0 to ${BATS_TMPDIR}/install
OUT
  refute_line 'Installing package-1.0.0...'
}

@test "falls back to compilation if no matching binary" {
  run_inline_definition <<DEF
binary linux-x86 "http://example.com/packages/binary-1.0.0.tar.gz"
binary linux-x64 "http://example.com/packages/binary-1.0.0.tar.gz"
install_package "package-1.0.0" "http://example.com/packages/package-1.0.0.tar.gz" copy
DEF

  assert_success
  assert_output - <<OUT
Downloading package-1.0.0.tar.gz...
-> http://example.com/packages/package-1.0.0.tar.gz
Installing package-1.0.0...
Installed package-1.0.0 to ${BATS_TMPDIR}/install
OUT
  refute_line 'Installing binary-1.0.0...'
}

@test "emits --compile help if binary installation fails" {
  run_inline_definition <<DEF
binary darwin-x64 "http://example.com/packages/binary-1.0.0.tar.gz#invalid_checksum_of_md5_length32"
install_package "package-1.0.0" "http://example.com/packages/package-1.0.0.tar.gz" copy
DEF

  assert_failure
  assert_line 'Downloading binary-1.0.0.tar.gz...'
  assert_line '-> http://example.com/packages/binary-1.0.0.tar.gz'
  assert_line 'Binary installation failed; try compiling from source with `--compile` flag'
  assert_line 'checksum mismatch: binary-1.0.0.tar.gz (file is corrupt)'
  assert_line 'expected invalid_checksum_of_md5_length32, got 6cb4716cde6cbeddb155043334005e27'
}

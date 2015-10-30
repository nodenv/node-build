#!/usr/bin/env bats

load test_helper

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
  assert_output_contains 'Downloading binary-1.0.0.tar.gz'
  assert_output_contains 'Installing binary-1.0.0...'
  assert_output_contains 'Installed binary-1.0.0'
}

@test "installs first of multiple matching binaries" {
  run_inline_definition <<DEF
binary darwin-x64 "http://example.com/packages/binary-1.0.0.tar.gz"
binary darwin-x64 "http://example.com/packages/secondary-1.0.0.tar.gz"
install_package "package-1.0.0" "http://example.com/packages/package-1.0.0.tar.gz" copy
DEF

  assert_success
  assert_output_contains 'Downloading binary-1.0.0.tar.gz'
  assert_output_contains 'Installing binary-1.0.0...'
  assert_output_contains 'Installed binary-1.0.0'
}

@test "falls back to compilation if no matching binary" {
  run_inline_definition <<DEF
binary linux-x86 "http://example.com/packages/binary-1.0.0.tar.gz"
binary linux-x64 "http://example.com/packages/binary-1.0.0.tar.gz"
install_package "package-1.0.0" "http://example.com/packages/package-1.0.0.tar.gz" copy
DEF

  assert_success
  assert_output_contains 'Downloading package-1.0.0.tar.gz'
  assert_output_contains 'Installing package-1.0.0...'
  assert_output_contains 'Installed package-1.0.0'
}

@test "emits --compile help if binary installation fails" {
  run_inline_definition <<DEF
binary darwin-x64 "http://example.com/packages/binary-1.0.0.tar.gz#invalidchecksum"
install_package "package-1.0.0" "http://example.com/packages/package-1.0.0.tar.gz" copy
DEF

  assert_failure
  assert_output_contains 'Downloading binary-1.0.0.tar.gz'
  assert_output_contains 'BUILD FAILED'
  assert_output_contains 'Binary installation failed; try compiling from source with `--compile` flag'
}

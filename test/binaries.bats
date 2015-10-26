#!/usr/bin/env bats

load test_helper

setup() {
  stub uname '-s : echo Darwin' '-s : echo Darwin' '-m : echo x86_64'
  stub curl \
    "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$3"\
    "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$3"
}

@test "installs binary if platform-matching distro" {
  run_inline_definition <<DEF
distro darwin-x64 "http://example.com/packages/binary-1.0.0.tar.gz"
install_package "package-1.0.0" "http://example.com/packages/package-1.0.0.tar.gz" copy
DEF

  assert_success
  assert_output_contains 'Downloading binary-1.0.0.tar.gz'
  assert_output_contains 'Installing binary-1.0.0...'
  assert_output_contains 'Installed binary-1.0.0'
}

@test "installs first of multiple matching binaries" {
  run_inline_definition <<DEF
distro darwin-x64 "http://example.com/packages/binary-1.0.0.tar.gz"
distro darwin-x64 "http://example.com/packages/secondary-1.0.0.tar.gz"
install_package "package-1.0.0" "http://example.com/packages/package-1.0.0.tar.gz" copy
DEF

  assert_success
  assert_output_contains 'Downloading binary-1.0.0.tar.gz'
  assert_output_contains 'Installing binary-1.0.0...'
  assert_output_contains 'Installed binary-1.0.0'
}

@test "falls back to compilation if no matching binary" {
  run_inline_definition <<DEF
distro linux-x86 "http://example.com/packages/binary-1.0.0.tar.gz"
distro linux-x64 "http://example.com/packages/binary-1.0.0.tar.gz"
install_package "package-1.0.0" "http://example.com/packages/package-1.0.0.tar.gz" copy
DEF

  assert_success
  assert_output_contains 'Downloading package-1.0.0.tar.gz'
  assert_output_contains 'Installing package-1.0.0...'
  assert_output_contains 'Installed package-1.0.0'
}

@test "falls back to compilation if binary installation fails" {
  run_inline_definition <<DEF
distro darwin-x64 "http://example.com/packages/binary-1.0.0.tar.gz#invalidchecksum"
install_package "package-1.0.0" "http://example.com/packages/package-1.0.0.tar.gz" copy
DEF

  assert_success
  assert_output_contains 'Downloading binary-1.0.0.tar.gz'
  assert_output_contains 'Downloading package-1.0.0.tar.gz'
  assert_output_contains 'Installing package-1.0.0...'
  assert_output_contains 'Installed package-1.0.0'
}

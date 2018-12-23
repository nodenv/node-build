#!/usr/bin/env bats

load test_helper
export MAKE=make
export MAKE_OPTS='-j 2'
export -n CFLAGS
export -n CC
export -n NODE_CONFIGURE_OPTS

@test "CC=clang by default on OS X 10.10" {
  mkdir -p "$INSTALL_ROOT"
  cd "$INSTALL_ROOT"

  stub uname '-s : echo Darwin'
  stub sw_vers '-productVersion : echo 10.10'
  stub cc 'false'
  stub brew 'false'
  stub make \
    'echo make $@' \
    'echo make $@'

  cat > ./configure <<CON
#!${BASH}
echo ./configure "\$@"
echo CC=\$CC
echo CFLAGS=\${CFLAGS-no}
CON
  chmod +x ./configure

  run_inline_definition <<DEF
exec 4<&1
build_package_standard node
DEF

  assert_success
  assert_output - <<OUT
./configure --prefix=$INSTALL_ROOT
CC=clang
CFLAGS=no
make -j 2
make install
OUT
}

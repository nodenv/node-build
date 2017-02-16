#!/usr/bin/env bats

load test_helper
export NODE_BUILD_CACHE_PATH="$BATS_TMPDIR/cache"
export MAKE=make
export MAKE_OPTS="-j 2"
export CC=cc
export -n NODE_CONFIGURE_OPTS

setup() {
  ensure_not_found_in_path aria2c
  mkdir -p "$INSTALL_ROOT"
  stub sha1 false
  stub curl false
}

executable() {
  local file="$1"
  mkdir -p "${file%/*}"
  cat > "$file"
  chmod +x "$file"
}

cached_tarball() {
  mkdir -p "$NODE_BUILD_CACHE_PATH"
  pushd "$NODE_BUILD_CACHE_PATH" >/dev/null
  tarball "$@"
  popd >/dev/null
}

tarball() {
  local name="$1"
  local path="$PWD/$name"
  local configure="$path/configure"
  shift 1

  executable "$configure" <<OUT
#!$BASH
echo "$name: \$@" \${NODEOPT:+NODEOPT=\$NODEOPT} >> build.log
OUT

  for file; do
    mkdir -p "$(dirname "${path}/${file}")"
    touch "${path}/${file}"
  done

  tar czf "${path}.tar.gz" -C "${path%/*}" "$name"
}

stub_make_install() {
  stub "$MAKE" \
    " : echo \"$MAKE \$@\" >> build.log" \
    "install : echo \"$MAKE \$@\" >> build.log && cat build.log >> '$INSTALL_ROOT/build.log'"
}

assert_build_log() {
  run cat "$INSTALL_ROOT/build.log"
  assert_output
}

@test "apply node patch before building" {
  cached_tarball "node-v4.0.0"

  stub uname '-s : echo Linux'
  stub brew false
  stub_make_install
  stub patch ' : echo patch "$@" | sed -E "s/\.[[:alnum:]]+$/.XXX/" >> build.log'

  TMPDIR="$BATS_TMPDIR" install_fixture --patch definitions/vanilla-node <<<""
  assert_success

  unstub uname
  unstub make
  unstub patch

  assert_build_log <<OUT
patch -p0 --force -i $BATS_TMPDIR/node-patch.XXX
node-v4.0.0: --prefix=$INSTALL_ROOT
make -j 2
make install
OUT
}

@test "apply node patch from git diff before building" {
  cached_tarball "node-v4.0.0"

  stub uname '-s : echo Linux'
  stub brew false
  stub_make_install
  stub patch ' : echo patch "$@" | sed -E "s/\.[[:alnum:]]+$/.XXX/" >> build.log'

  TMPDIR="$BATS_TMPDIR" install_fixture --patch definitions/vanilla-node <<<"diff --git a/script.rb"
  assert_success

  unstub uname
  unstub make
  unstub patch

  assert_build_log <<OUT
patch -p1 --force -i $BATS_TMPDIR/node-patch.XXX
node-v4.0.0: --prefix=$INSTALL_ROOT
make -j 2
make install
OUT
}

@test "number of CPU cores defaults to 2" {
  cached_tarball "node-v4.0.0"

  stub uname '-s : echo Darwin'
  stub sysctl false
  stub_make_install

  export -n MAKE_OPTS
  run_inline_definition <<DEF
install_package "node-v4.0.0" "http://nodejs.org/dist/v4.0.0/node-v4.0.0.tar.gz"
DEF
  assert_success

  unstub uname
  unstub make

  assert_build_log <<OUT
node-v4.0.0: --prefix=$INSTALL_ROOT
make -j 2
make install
OUT
}

@test "number of CPU cores is detected on Mac" {
  cached_tarball "node-v4.0.0"

  stub uname '-s : echo Darwin'
  stub sysctl '-n hw.ncpu : echo 4'
  stub_make_install

  export -n MAKE_OPTS
  run_inline_definition <<DEF
install_package "node-v4.0.0" "http://nodejs.org/dist/v4.0.0/node-v4.0.0.tar.gz"
DEF
  assert_success

  unstub uname
  unstub sysctl
  unstub make

  assert_build_log <<OUT
node-v4.0.0: --prefix=$INSTALL_ROOT
make -j 4
make install
OUT
}

@test "number of CPU cores is detected on FreeBSD" {
  cached_tarball "node-v4.0.0"

  stub uname '-s : echo FreeBSD'
  stub sysctl '-n hw.ncpu : echo 1'
  stub_make_install

  export -n MAKE_OPTS
  run_inline_definition <<DEF
install_package "node-v4.0.0" "http://nodejs.org/dist/v4.0.0/node-v4.0.0.tar.gz"
DEF
  assert_success

  unstub uname
  unstub sysctl
  unstub make

  assert_build_log <<OUT
node-v4.0.0: --prefix=$INSTALL_ROOT
make -j 1
make install
OUT
}

@test "setting NODE_MAKE_INSTALL_OPTS to a multi-word string" {
  cached_tarball "node-v4.0.0"

  stub uname '-s : echo Linux'
  stub_make_install

  export NODE_MAKE_INSTALL_OPTS="DOGE=\"such wow\""
  run_inline_definition <<DEF
install_package "node-v4.0.0" "http://nodejs.org/dist/v4.0.0/node-v4.0.0.tar.gz"
DEF
  assert_success

  unstub uname
  unstub make

  assert_build_log <<OUT
node-v4.0.0: --prefix=$INSTALL_ROOT
make -j 2
make install DOGE="such wow"
OUT
}

@test "setting MAKE_INSTALL_OPTS to a multi-word string" {
  cached_tarball "node-v4.0.0"

  stub uname '-s : echo Linux'
  stub_make_install

  export MAKE_INSTALL_OPTS="DOGE=\"such wow\""
  run_inline_definition <<DEF
install_package "node-v4.0.0" "http://nodejs.org/dist/v4.0.0/node-v4.0.0.tar.gz"
DEF
  assert_success

  unstub uname
  unstub make

  assert_build_log <<OUT
node-v4.0.0: --prefix=$INSTALL_ROOT
make -j 2
make install DOGE="such wow"
OUT
}

@test "custom relative install destination" {
  export NODE_BUILD_CACHE_PATH="$FIXTURE_ROOT"

  cd "$BATS_TMPDIR"
  install_fixture definitions/without-checksum ./here
  assert_success
  assert [ -x ./here/bin/package ]
}

@test "make on FreeBSD 9 defaults to gmake" {
  cached_tarball "node-v4.0.0"

  stub uname "-s : echo FreeBSD" "-r : echo 9.1"
  MAKE=gmake stub_make_install

  MAKE= install_fixture definitions/vanilla-node
  assert_success

  unstub gmake
  unstub uname
}

@test "make on FreeBSD 10" {
  cached_tarball "node-v4.0.0"

  stub uname "-s : echo FreeBSD" "-r : echo 10.0-RELEASE"
  stub_make_install

  MAKE= install_fixture definitions/vanilla-node
  assert_success

  unstub uname
}

@test "can use NODE_CONFIGURE to apply a patch" {
  cached_tarball "node-v4.0.0"

  executable "${BATS_TMPDIR}/custom-configure" <<CONF
#!$BASH
apply -p1 -i /my/patch.diff
exec ./configure "\$@"
CONF

  stub uname '-s : echo Linux'
  stub apply 'echo apply "$@" >> build.log'
  stub_make_install

  export NODE_CONFIGURE="${BATS_TMPDIR}/custom-configure"
  run_inline_definition <<DEF
install_package "node-v4.0.0" "http://nodejs.org/dist/v4.0.0/node-v4.0.0.tar.gz"
DEF
  assert_success

  unstub uname
  unstub make
  unstub apply

  assert_build_log <<OUT
apply -p1 -i /my/patch.diff
node-v4.0.0: --prefix=$INSTALL_ROOT
make -j 2
make install
OUT
}

@test "copy strategy forces overwrite" {
  export NODE_BUILD_CACHE_PATH="$FIXTURE_ROOT"

  mkdir -p "$INSTALL_ROOT/bin"
  touch "$INSTALL_ROOT/bin/package"
  chmod -w "$INSTALL_ROOT/bin/package"

  install_fixture definitions/without-checksum
  assert_success

  run "$INSTALL_ROOT/bin/package" "world"
  assert_success "hello world"
}

@test "non-writable TMPDIR aborts build" {
  export TMPDIR="${BATS_TMPDIR}/build"
  mkdir -p "$TMPDIR"
  chmod -w "$TMPDIR"

  touch "${BATS_TMPDIR}/build-definition"
  run node-build "${BATS_TMPDIR}/build-definition" "$INSTALL_ROOT"
  assert_failure "node-build: TMPDIR=$TMPDIR is set to a non-accessible location"
}

@test "non-executable TMPDIR aborts build" {
  export TMPDIR="${BATS_TMPDIR}/build"
  mkdir -p "$TMPDIR"
  chmod -x "$TMPDIR"

  touch "${BATS_TMPDIR}/build-definition"
  run node-build "${BATS_TMPDIR}/build-definition" "$INSTALL_ROOT"
  assert_failure "node-build: TMPDIR=$TMPDIR is set to a non-accessible location"
}

@test "initializes LDFLAGS directories" {
  cached_tarball "node-v4.0.0"

  export LDFLAGS="-L ${BATS_TEST_DIRNAME}/what/evs"
  run_inline_definition <<DEF
install_package "node-v4.0.0" "http://nodejs.org/dist/v4.0.0/node-v4.0.0.tar.gz" ldflags_dirs
DEF
  assert_success

  assert [ -d "${INSTALL_ROOT}/lib" ]
  assert [ -d "${BATS_TEST_DIRNAME}/what/evs" ]
}

@test "directory structure is fixed for jxcore source builds" {
  export NODE_BUILD_CACHE_PATH="$FIXTURE_ROOT"
  stub_make_install

  install_fixture --compile definitions/jxcore
  assert_success

  assert [ -d "${INSTALL_ROOT}/bin" ]
  assert [ -L "${INSTALL_ROOT}/bin/node" ]
}

@test "directory structure is fixed for jxcore binary builds" {
  export NODE_BUILD_CACHE_PATH="$FIXTURE_ROOT"
  stub_make_install

  install_fixture definitions/jxcore
  assert_success

  refute [ -e "${INSTALL_ROOT}/jx" ]
  assert [ -d "${INSTALL_ROOT}/bin" ]
  assert [ -x "${INSTALL_ROOT}/bin/jx" ]
  assert [ -L "${INSTALL_ROOT}/bin/npm" ]
  assert [ -L "${INSTALL_ROOT}/bin/node" ]
}

@test "jxcore's custom npm is installed and configured" {
  export NODE_BUILD_CACHE_PATH="$FIXTURE_ROOT"
  stub_make_install

  install_fixture definitions/jxcore
  assert_success

  assert [ -e "${INSTALL_ROOT}/bin/jx.config" ]
  assert [ -d "${INSTALL_ROOT}/libexec/.jx/npm" ]
  assert [ -e "${INSTALL_ROOT}/libexec/.jx/v 0.3.0.7" ]
  assert grep "\"npmjxPath\": \"${INSTALL_ROOT}/libexec\"" "${INSTALL_ROOT}/bin/jx.config"
}

@test "jxcore can specify spidermonkey engine" {
  cached_tarball "jxcore-sm-1.0.0"

  stub_make_install

  run_inline_definition <<DEF
install_package "jxcore-sm-1.0.0" "http://jxcore.s3.amazonaws.com/jxcore-sm-1.0.0.tar.gz" jxcore_spidermonkey standard
DEF
  assert_success

  unstub make

  assert_build_log <<OUT
jxcore-sm-1.0.0: --prefix=$INSTALL_ROOT --engine-mozilla
make -j 2
make install
OUT
}

@test "jxcore can specify v8 3.28 engine" {
  cached_tarball "jxcore-v8-1.0.0"

  stub_make_install

  run_inline_definition <<DEF
install_package "jxcore-v8-1.0.0" "http://jxcore.s3.amazonaws.com/jxcore-v8-1.0.0.tar.gz" jxcore_v8_328 standard
DEF
  assert_success

  unstub make

  assert_build_log <<OUT
jxcore-v8-1.0.0: --prefix=$INSTALL_ROOT --engine-v8-3-28
make -j 2
make install
OUT
}

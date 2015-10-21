#!/usr/bin/env bats

load test_helper
export NODE_BUILD_CACHE_PATH="$TMP/cache"
export MAKE=make
export MAKE_OPTS="-j 2"
export CC=cc
export -n NODE_CONFIGURE_OPTS

setup() {
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

  stub brew false
  stub_make_install
  stub patch ' : echo patch "$@" | sed -E "s/\.[[:alnum:]]+$/.XXX/" >> build.log'

  TMPDIR="$TMP" install_fixture --patch definitions/vanilla-node <<<""
  assert_success

  unstub make
  unstub patch

  assert_build_log <<OUT
patch -p0 --force -i $TMP/node-patch.XXX
node-v4.0.0: --prefix=$INSTALL_ROOT
make -j 2
make install
OUT
}

@test "apply node patch from git diff before building" {
  cached_tarball "node-v4.0.0"

  stub brew false
  stub_make_install
  stub patch ' : echo patch "$@" | sed -E "s/\.[[:alnum:]]+$/.XXX/" >> build.log'

  TMPDIR="$TMP" install_fixture --patch definitions/vanilla-node <<<"diff --git a/script.rb"
  assert_success

  unstub make
  unstub patch

  assert_build_log <<OUT
patch -p1 --force -i $TMP/node-patch.XXX
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

  stub_make_install

  export NODE_MAKE_INSTALL_OPTS="DOGE=\"such wow\""
  run_inline_definition <<DEF
install_package "node-v4.0.0" "http://nodejs.org/dist/v4.0.0/node-v4.0.0.tar.gz"
DEF
  assert_success

  unstub make

  assert_build_log <<OUT
node-v4.0.0: --prefix=$INSTALL_ROOT
make -j 2
make install DOGE="such wow"
OUT
}

@test "setting MAKE_INSTALL_OPTS to a multi-word string" {
  cached_tarball "node-v4.0.0"

  stub_make_install

  export MAKE_INSTALL_OPTS="DOGE=\"such wow\""
  run_inline_definition <<DEF
install_package "node-v4.0.0" "http://nodejs.org/dist/v4.0.0/node-v4.0.0.tar.gz"
DEF
  assert_success

  unstub make

  assert_build_log <<OUT
node-v4.0.0: --prefix=$INSTALL_ROOT
make -j 2
make install DOGE="such wow"
OUT
}

@test "custom relative install destination" {
  export NODE_BUILD_CACHE_PATH="$FIXTURE_ROOT"

  cd "$TMP"
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

  executable "${TMP}/custom-configure" <<CONF
#!$BASH
apply -p1 -i /my/patch.diff
exec ./configure "\$@"
CONF

  stub apply 'echo apply "$@" >> build.log'
  stub_make_install

  export NODE_CONFIGURE="${TMP}/custom-configure"
  run_inline_definition <<DEF
install_package "node-v4.0.0" "http://nodejs.org/dist/v4.0.0/node-v4.0.0.tar.gz"
DEF
  assert_success

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
  export TMPDIR="${TMP}/build"
  mkdir -p "$TMPDIR"
  chmod -w "$TMPDIR"

  touch "${TMP}/build-definition"
  run node-build "${TMP}/build-definition" "$INSTALL_ROOT"
  assert_failure "node-build: TMPDIR=$TMPDIR is set to a non-accessible location"
}

@test "non-executable TMPDIR aborts build" {
  export TMPDIR="${TMP}/build"
  mkdir -p "$TMPDIR"
  chmod -x "$TMPDIR"

  touch "${TMP}/build-definition"
  run node-build "${TMP}/build-definition" "$INSTALL_ROOT"
  assert_failure "node-build: TMPDIR=$TMPDIR is set to a non-accessible location"
}

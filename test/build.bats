#!/usr/bin/env bats

load test_helper
export NODE_BUILD_CACHE_PATH="$TMP/cache"
export MAKE=make
export MAKE_OPTS="-j 2"

setup() {
  mkdir -p "$INSTALL_ROOT"
  stub md5 false
  stub curl false
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

  mkdir -p "$path"
  cat > "$configure" <<OUT
#!$BASH
echo "$name: \$@" \${NODEOPT:+NODEOPT=\$NODEOPT} >> build.log
OUT
  chmod +x "$configure"

  for file; do
    mkdir -p "$(dirname "${path}/${file}")"
    touch "${path}/${file}"
  done

  tar czf "${path}.tar.gz" -C "${path%/*}" "$name"
}

stub_make_install() {
  stub "$MAKE" \
    " : echo \"$MAKE \$@\" >> build.log" \
    "install : cat build.log >> '$INSTALL_ROOT/build.log'"
}

assert_build_log() {
  run cat "$INSTALL_ROOT/build.log"
  assert_output
}

@test "apply ruby patch before building" {
  cached_tarball "yaml-0.1.4"
  cached_tarball "ruby-2.0.0"

  stub brew false
  stub_make_install
  stub_make_install
  stub patch ' : echo patch "$@" >> build.log'

  install_fixture --patch definitions/needs-yaml
  assert_success

  unstub make
  unstub patch

  assert_build_log <<OUT
yaml-0.1.4: --prefix=$INSTALL_ROOT
make -j 2
patch -p0 -i -
ruby-2.0.0: --prefix=$INSTALL_ROOT
make -j 2
OUT
}

@test "readline is linked from Homebrew" {
  cached_tarball "ruby-2.0.0"

  readline_libdir="$TMP/homebrew-readline"
  mkdir -p "$readline_libdir"

  stub brew "--prefix readline : echo '$readline_libdir'"
  stub_make_install

  run_inline_definition <<DEF
install_package "ruby-2.0.0" "http://ruby-lang.org/ruby/2.0/ruby-2.0.0.tar.gz"
DEF
  assert_success

  unstub brew
  unstub make

  assert_build_log <<OUT
ruby-2.0.0: --prefix=$INSTALL_ROOT --with-readline-dir=$readline_libdir
make -j 2
OUT
}

@test "readline is not linked from Homebrew when explicitly defined" {
  cached_tarball "ruby-2.0.0"

  stub brew
  stub_make_install

  export RUBY_CONFIGURE_OPTS='--with-readline-dir=/custom'
  run_inline_definition <<DEF
install_package "ruby-2.0.0" "http://ruby-lang.org/ruby/2.0/ruby-2.0.0.tar.gz"
DEF
  assert_success

  unstub brew
  unstub make

  assert_build_log <<OUT
ruby-2.0.0: --prefix=$INSTALL_ROOT --with-readline-dir=/custom
make -j 2
OUT
}

@test "number of CPU cores defaults to 2" {
  cached_tarball "ruby-2.0.0"

  stub uname '-s : echo Darwin'
  stub sysctl false
  stub_make_install

  export -n MAKE_OPTS
  run_inline_definition <<DEF
install_package "ruby-2.0.0" "http://ruby-lang.org/ruby/2.0/ruby-2.0.0.tar.gz"
DEF
  assert_success

  unstub uname
  unstub make

  assert_build_log <<OUT
ruby-2.0.0: --prefix=$INSTALL_ROOT
make -j 2
OUT
}

@test "number of CPU cores is detected on Mac" {
  cached_tarball "ruby-2.0.0"

  stub uname '-s : echo Darwin'
  stub sysctl '-n hw.ncpu : echo 4'
  stub_make_install

  export -n MAKE_OPTS
  run_inline_definition <<DEF
install_package "ruby-2.0.0" "http://ruby-lang.org/ruby/2.0/ruby-2.0.0.tar.gz"
DEF
  assert_success

  unstub uname
  unstub sysctl
  unstub make

  assert_build_log <<OUT
ruby-2.0.0: --prefix=$INSTALL_ROOT
make -j 4
OUT
}

@test "custom relative install destination" {
  export NODE_BUILD_CACHE_PATH="$FIXTURE_ROOT"

  cd "$TMP"
  install_fixture definitions/without-checksum ./here
  assert_success
  assert [ -x ./here/bin/package ]
}

@test "make on FreeBSD defaults to gmake" {
  cached_tarball "ruby-2.0.0"

  stub uname "-s : echo FreeBSD"
  MAKE=gmake stub_make_install

  MAKE= install_fixture definitions/vanilla-ruby
  assert_success

  unstub gmake
  unstub uname
}

@test "can use RUBY_CONFIGURE to apply a patch" {
  cached_tarball "ruby-2.0.0"

  cat > "${TMP}/custom-configure" <<CONF
#!$BASH
apply -p1 -i /my/patch.diff
exec ./configure "\$@"
CONF
  chmod +x "${TMP}/custom-configure"

  stub apply 'echo apply "$@" >> build.log'
  stub_make_install

  export RUBY_CONFIGURE="${TMP}/custom-configure"
  run_inline_definition <<DEF
install_package "ruby-2.0.0" "http://ruby-lang.org/pub/ruby-2.0.0.tar.gz"
DEF
  assert_success

  unstub make
  unstub apply

  assert_build_log <<OUT
apply -p1 -i /my/patch.diff
ruby-2.0.0: --prefix=$INSTALL_ROOT
make -j 2
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

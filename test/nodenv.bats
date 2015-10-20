#!/usr/bin/env bats

load test_helper
export NODENV_ROOT="${TMP}/nodenv"

setup() {
  stub nodenv-hooks 'install : true'
  stub nodenv-rehash 'true'
}

stub_node_build() {
  stub node-build "--lib : $BATS_TEST_DIRNAME/../bin/node-build --lib" "$@"
}

@test "install proper" {
  stub_node_build 'echo node-build "$@"'

  run nodenv-install 4.1.2
  assert_success "node-build 4.1.2 ${NODENV_ROOT}/versions/4.1.2"

  unstub node-build
  unstub nodenv-hooks
  unstub nodenv-rehash
}

@test "install nodenv local version by default" {
  stub_node_build 'echo node-build "$1"'
  stub nodenv-local 'echo 4.1.2'

  run nodenv-install
  assert_success "node-build 4.1.2"

  unstub node-build
  unstub nodenv-local
}

@test "list available versions" {
  stub_node_build \
    "--definitions : echo 0.8.7 0.10.40 4.1.2 | tr ' ' $'\\n'"

  run nodenv-install --list
  assert_success
  assert_output <<OUT
Available versions:
  0.8.7
  0.10.40
  4.1.2
OUT

  unstub node-build
}

@test "nonexistent version" {
  stub brew false
  stub_node_build 'echo ERROR >&2 && exit 2' \
    "--definitions : echo 0.8.7 0.10.36 0.10.40 4.1.2 | tr ' ' $'\\n'"

  run nodenv-install 0.10
  assert_failure
  assert_output <<OUT
ERROR

The following versions contain \`0.10' in the name:
  0.10.36
  0.10.40

See all available versions with \`nodenv install --list'.

If the version you need is missing, try upgrading node-build:

  cd ${BATS_TEST_DIRNAME}/.. && git pull
OUT

  unstub node-build
}

@test "Homebrew upgrade instructions" {
  stub brew "--prefix : echo '${BATS_TEST_DIRNAME%/*}'"
  stub_node_build 'echo ERROR >&2 && exit 2' \
    "--definitions : true"

  run nodenv-install 5.0.0
  assert_failure
  assert_output <<OUT
ERROR

See all available versions with \`nodenv install --list'.

If the version you need is missing, try upgrading node-build:

  brew update && brew upgrade node-build
OUT

  unstub brew
  unstub node-build
}

@test "no build definitions from plugins" {
  assert [ ! -e "${NODENV_ROOT}/plugins" ]
  stub_node_build 'echo $NODE_BUILD_DEFINITIONS'

  run nodenv-install 4.1.2
  assert_success ""
}

@test "some build definitions from plugins" {
  mkdir -p "${NODENV_ROOT}/plugins/foo/share/node-build"
  mkdir -p "${NODENV_ROOT}/plugins/bar/share/node-build"
  stub_node_build "echo \$NODE_BUILD_DEFINITIONS | tr ':' $'\\n'"

  run nodenv-install 4.1.2
  assert_success
  assert_output <<OUT

${NODENV_ROOT}/plugins/bar/share/node-build
${NODENV_ROOT}/plugins/foo/share/node-build
OUT
}

@test "list build definitions from plugins" {
  mkdir -p "${NODENV_ROOT}/plugins/foo/share/node-build"
  mkdir -p "${NODENV_ROOT}/plugins/bar/share/node-build"
  stub_node_build "--definitions : echo \$NODE_BUILD_DEFINITIONS | tr ':' $'\\n'"

  run nodenv-install --list
  assert_success
  assert_output <<OUT
Available versions:
  
  ${NODENV_ROOT}/plugins/bar/share/node-build
  ${NODENV_ROOT}/plugins/foo/share/node-build
OUT
}

@test "completion results include build definitions from plugins" {
  mkdir -p "${NODENV_ROOT}/plugins/foo/share/node-build"
  mkdir -p "${NODENV_ROOT}/plugins/bar/share/node-build"
  stub node-build "--definitions : echo \$NODE_BUILD_DEFINITIONS | tr ':' $'\\n'"

  run nodenv-install --complete
  assert_success
  assert_output <<OUT

${NODENV_ROOT}/plugins/bar/share/node-build
${NODENV_ROOT}/plugins/foo/share/node-build
OUT
}

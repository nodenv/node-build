#!/usr/bin/env bats

load test_helper

setup() {
  export NODENV_ROOT="${TMP}/nodenv"
  export HOOK_PATH="${TMP}/i has hooks"
  mkdir -p "$HOOK_PATH"
}

@test "nodenv-install hooks" {
  cat > "${HOOK_PATH}/install.bash" <<OUT
before_install 'echo before: \$PREFIX'
after_install 'echo after: \$STATUS'
OUT
  stub nodenv-hooks "install : echo '$HOOK_PATH'/install.bash"
  stub nodenv-rehash "echo rehashed"

  definition="${TMP}/4.0.0"
  cat > "$definition" <<<"echo node-build"
  run nodenv-install "$definition"

  assert_success
  assert_output <<-OUT
before: ${NODENV_ROOT}/versions/4.0.0
node-build
after: 0
rehashed
OUT
}

@test "nodenv-uninstall hooks" {
  cat > "${HOOK_PATH}/uninstall.bash" <<OUT
before_uninstall 'echo before: \$PREFIX'
after_uninstall 'echo after.'
rm() {
  echo "rm \$@"
  command rm "\$@"
}
OUT
  stub nodenv-hooks "uninstall : echo '$HOOK_PATH'/uninstall.bash"
  stub nodenv-rehash "echo rehashed"

  mkdir -p "${NODENV_ROOT}/versions/4.0.0"
  run nodenv-uninstall -f 4.0.0

  assert_success
  assert_output <<-OUT
before: ${NODENV_ROOT}/versions/4.0.0
rm -rf ${NODENV_ROOT}/versions/4.0.0
rehashed
after.
OUT

  assert [ ! -d "${NODENV_ROOT}/versions/4.0.0" ]
}

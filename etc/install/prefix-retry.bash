retry_without_prefix() {
  [ "$STATUS" = 2 ] || return 0

  fallback_name=${VERSION_NAME#node-}
  fallback_name=${fallback_name#v}

  [ "$fallback_name" != "$VERSION_NAME" ] || return 0

  echo
  echo "Attempting fallback install without \`node-/v' prefix: $fallback_name"
  echo

  exec nodenv-install ${FORCE+-f} ${SKIP_EXISTING+-s} ${SKIP_BINARY+-c} ${NODENV_BUILD_ROOT+-k} ${VERBOSE+-v} ${HAS_PATCH+-p} "$fallback_name"
}

after_install retry_without_prefix

#!/usr/bin/env bats

load test_helper

setup() {
  cd "$BATS_TEST_DIRNAME/../share/node-build"
}

@test "definitions have EOL and LTS warnings" {
  run echo "$("$BATS_TEST_DIRNAME/helpers/warning_messages" 2>/dev/null)"
  assert_output ""
}

#!/usr/bin/env bats

load test_helper

@test "definitions have EOL and LTS warnings" {
  run echo "$("$BATS_TEST_DIRNAME/helpers/warning_messages" "$BATS_TEST_DIRNAME/../share/node-build" 2>/dev/null)"
  assert_output ""
}

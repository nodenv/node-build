#!/usr/bin/env bats

load test_helper

@test "definitions have EOL and LTS warnings" {
  run "$BATS_TEST_DIRNAME/../script/lint/lts" "$BATS_TEST_DIRNAME/../share/node-build"
  assert_success
}

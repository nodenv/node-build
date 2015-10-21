#!/usr/bin/env bats

load test_helper

@test "not enough arguments for node-build" {
  # use empty inline definition so nothing gets built anyway
  local definition="${TMP}/build-definition"
  echo '' > "$definition"

  run node-build "$definition"
  assert_failure
  assert_output_contains 'Usage: node-build'
}

@test "extra arguments for node-build" {
  # use empty inline definition so nothing gets built anyway
  local definition="${TMP}/build-definition"
  echo '' > "$definition"

  run node-build "$definition" "${TMP}/install" ""
  assert_failure
  assert_output_contains 'Usage: node-build'
}

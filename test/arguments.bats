#!/usr/bin/env bats

load test_helper

@test "not enough arguments for node-build" {
  mkdir -p "$TMP"
  # use empty inline definition so nothing gets built anyway
  touch "${TMP}/empty-definition"
  run node-build "${TMP}/empty-definition"
  assert_failure
  assert_output --partial 'Usage: node-build'
}

@test "extra arguments for node-build" {
  mkdir -p "$TMP"
  # use empty inline definition so nothing gets built anyway
  touch "${TMP}/empty-definition"
  run node-build "${TMP}/empty-definition" "${TMP}/install" ""
  assert_failure
  assert_output --partial 'Usage: node-build'
}

#!/usr/bin/env bats

load test_helper

assert_eol() {
  run grep -e "warn_eol" --files-without-match "$@"
  assert_output ""
}

assert_lts() {
  run grep -e "warn_lts" --files-without-match "$@"
  assert_output ""
}

assert_warning() {
  state=$1
  date=$2

  if [ "$(date -j +'%s')" -gt $(date -j -f "%F" "$date" "+%s") ]; then
    "assert_$state" "${@:3}"
  fi
}

@test "EOL nodes have warnings" {
  assert_eol 0.*
  assert_eol 4.*
  assert_eol 5.*
  assert_eol 7.*
  assert_eol 9.*
  assert_eol iojs-*
  assert_eol jxcore+*
}

@test "Node 6 is in LTS Maintenace April 2018 - April 2019" {
  assert_warning eol '2019-04-01' 6.*
  assert_warning lts '2018-04-30' 6.*
}

@test "Node 8 is in LTS Maintenace April 2019 - Dec 2019" {
  assert_warning eol '2019-12-01' 8.*
  assert_warning lts '2019-04-01' 8.*
}

@test "Node 10 is LTS Maintenance April 2020 - April 2021" {
  assert_warning eol '2021-04-01' 10.*
  assert_warning lts '2020-04-01' 10.*
}

@test "Node 11 is EOL June 2019" {
  assert_warning eol '2019-06-01' 11.*
}

@test "Node 12 is LTS Maintenance April 2021 - April 2022" {
  assert_warning eol '2022-04-01' 12.*
  assert_warning lts '2021-04-01' 12.*
}

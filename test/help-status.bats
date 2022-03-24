#!/usr/bin/env bats

. test/helpers.sh

@test "_is_bad exits 0 if status is bad" {
  run _is_bad 1
  [ "$status" -eq 0 ]
}

@test "_is_bad exits 1 if status is good or workable" {
  run _is_bad 0
  [ "$status" -eq 1 ]
  run _is_bad 10
  [ "$status" -eq 1 ]
}
#!/usr/bin/env bats

. test/helpers.sh

@test "tell outputs to stdout" {
  run --separate-stderr tell "test"
  [ "$output" = 'test' ]
  [ -z "$stderr" ]
}

@test "ohno outputs to stderr" {
  run --separate-stderr ohno "test"
  [ "$stderr" = 'test' ]
  [ -z "$output" ]
}

@test "think outputs to stdout" {
  run --separate-stderr think "test"
  [ "$output" = 'test' ]
  [ -z "$stderr" ]
}
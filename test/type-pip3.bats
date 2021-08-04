#!/usr/bin/env bats

. test/helpers.sh
pip3 () { . $BORK_SOURCE_DIR/types/pip3.sh $*; }

setup () {
  respond_to "pip3 list" "cat $fixtures/pip3-list.txt"
}

@test "pip3 status: returns FAILED_PRECONDITION without pip3 exec" {
  respond_to "which pip3" "return 1"
  run pip3 status foo
  [ "$status" -eq $STATUS_FAILED_PRECONDITION ]
}

@test "pip3 status: returns MISSING if pkg isn't installed" {
  run pip3 status baz
  [ "$status" -eq $STATUS_MISSING ]
}

@test "pip3 status: returns OK if pkg is installed" {
  run pip3 status foo
  [ "$status" -eq $STATUS_OK ]
}

@test "pip3 install: performs installation" {
  run pip3 install foo
  [ "$status" -eq 0 ]
  run baked_output
  [ "${lines[0]}" = "pip3 install foo" ]
}

@test "pip3 inspect: returns FAILED_PRECONDITION without pip3 exec" {
    respond_to "which pip3" "return 1"
    run pip3 inspect
    [ "$status" -eq $STATUS_FAILED_PRECONDITION ]
}

@test "pip3 inspect: returns OK if preconditions met" {
    run pip3 inspect
    [ "$status" -eq $STATUS_OK ]
}

@test "pip3 remove: performs uninstallation" {
  run pip3 remove foo
  [ "$status" -eq 0 ]
  run baked_output
  [ "${lines[0]}" = "pip3 uninstall foo" ]
}
#!/usr/bin/env bats

. test/helpers.sh
pip () { . $BORK_SOURCE_DIR/types/pip.sh $*; }

setup () {
  respond_to "pip list" "cat $fixtures/pip-list.txt"
}

@test "pip status: returns FAILED_PRECONDITION without pip exec" {
  respond_to "which pip" "return 1"
  run pip status foo
  [ "$status" -eq $STATUS_FAILED_PRECONDITION ]
}

@test "pip status: returns MISSING if pkg isn't installed" {
  run pip status baz
  [ "$status" -eq $STATUS_MISSING ]
}

@test "pip status: returns OK if pkg is installed" {
  run pip status foo
  [ "$status" -eq $STATUS_OK ]
}

@test "pip install: performs installation" {
  run pip install foo
  [ "$status" -eq 0 ]
  run baked_output
  [ "${lines[0]}" = "pip install foo" ]
}

@test "pip install: performs installation with sudo flag" {
  run pip install foo --sudo
  [ "$status" -eq 0 ]
  run baked_output
  [ "${lines[0]}" = "sudo pip install foo" ]
}

@test "pip remove: performs uninstallation" {
  run pip remove foo
  [ "$status" -eq 0 ]
  run baked_output
  [ "${lines[0]}" = "pip uninstall foo" ]
}

@test "pip remove: performs uninstallation with sudo flag" {
  run pip remove foo --sudo
  [ "$status" -eq 0 ]
  run baked_output
  [ "${lines[0]}" = "sudo pip uninstall foo" ]
}

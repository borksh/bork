#!/usr/bin/env bats

. test/helpers.sh

check () { . $BORK_SOURCE_DIR/types/check.sh $*; }

@test "should check and pass if exits 0" {
  run check status true
  [ "$status" -eq $STATUS_OK ]
}

@test "should check and fail if exits 1" {
  run check status false
  [ "$status" -eq $STATUS_FAILED ]
}

@test "should check and fail if exits any >0" {
  respond_to "custom_code" "return 123" 
  run check status custom_code
  [ "$status" -eq $STATUS_FAILED ]
}
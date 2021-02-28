#!/usr/bin/env bats

. test/helpers.sh

shells () { . $BORK_SOURCE_DIR/types/shells.sh $*; }

setup () {
  respond_to "cat /etc/shells" "cat $fixtures/shells.txt"
  respond_to "sudo tee -a /etc/shells" "echo '/bin/fish'"
}

@test "shells status: returns MISSING when shell is missing" {
  run shells status /bin/fish
  [ "$status" -eq $STATUS_MISSING ]
}

@test "shells status: returns OK when shell is present" {
  run shells status /bin/zsh
  [ "$status" -eq $STATUS_OK ]
}

@test "shells install: returns OK when shell installs" {
  run shells install /bin/fish
  [ "$status" -eq $STATUS_OK ]
  run baked_output
  [ "${lines[0]}" = 'echo /bin/fish' ]
  [ "${lines[1]}" = 'sudo tee -a /etc/shells' ]
}

@test "shells inspect: returns OK" {
    run shells inspect
    [ "$status" -eq $STATUS_OK ]
}
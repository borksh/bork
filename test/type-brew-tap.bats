#!/usr/bin/env bats

. test/helpers.sh
brew-tap () { . $BORK_SOURCE_DIR/types/brew-tap.sh $*; }

setup () {
    respond_to "uname -s" "echo Darwin"
    respond_to "brew tap" "cat $fixtures/brew-tap-list.txt"
}

@test "brew-tap status reports missing when untapped" {
    run brew-tap status some/tap
    [ "$status" -eq $STATUS_MISSING ]
}

@test "brew-tap status reports ok when provided tap name has capitals" {
    run brew-tap status Caskroom/cask
    [ "$status" -eq $STATUS_OK ]
}

@test "brew-tap install installs tap" {
    run brew-tap install homebrew/science
    [ "$status" -eq 0 ]
    run baked_output
    [ "$output" = 'brew tap homebrew/science' ]
}

@test "brew-tap inspect: returns FAILED_PRECONDITION without brew exec" {
    respond_to "which brew" "return 1"
    run brew-tap inspect
    [ "$status" -eq $STATUS_FAILED_PRECONDITION ]
}

@test "brew-tap inspect: returns OK if preconditions met" {
    run brew-tap inspect
    [ "$status" -eq $STATUS_OK ]
}

@test "brew-tap remove untaps tap" {
    run brew-tap remove homebrew/science
    [ "$status" -eq 0 ]
    run baked_output
    [ "$output" = 'brew untap homebrew/science' ]
}

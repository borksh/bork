#!/usr/bin/env bats

. test/helpers.sh
cask () { . $BORK_SOURCE_DIR/types/cask.sh $*; }

setup () {
  respond_to "uname -s" "echo Darwin"
  respond_to "which brew" "echo /usr/local/bin/brew"
  respond_to "brew list --cask" "cat $fixtures/cask-list.txt"
}

@test "cask status reports unsupported platforms" {
  respond_to "uname -s" "echo Linux"
  run cask status something
  [ "$status" -eq $STATUS_UNSUPPORTED_PLATFORM ]
}

@test "cask status reports missing brew exec" {
  respond_to "which brew" "return 1"
  run cask status something
  [ "$status" -eq $STATUS_FAILED_PRECONDITION ]
}

@test "cask status reports missing cask package" {
  respond_to "brew --version" "return 1"
  run cask status something
  [ "$status" -eq $STATUS_FAILED_PRECONDITION ]
}

@test "cask status reports an app is missing" {
  run cask status missing_app
  [ "$status" -eq $STATUS_MISSING ]
}

@test "cask status reports an app is current" {
  run cask status installed_app
  [ "$status" -eq $STATUS_MISSING ]
}

@test "cask status reports an app is outdated" {
  respond_to "brew info --cask installed_package" "cat $fixtures/cask-outdated-info.txt"
  run cask status installed_package
  [ "$status" -eq $STATUS_OUTDATED ]
}

@test "cask install runs 'install'" {
  run cask install missing_package
  [ "$status" -eq 0 ]
  run baked_output
  [ "$output" = 'brew install --cask missing_package' ]
}

@test "cask upgrade performs a force install and cleans up old versions" {
  run cask upgrade installed_package
  [ "$status" -eq 0 ]
  run baked_output
  [ "${lines[0]}" = "rm -rf /usr/local/Caskroom/installed_package" ]
  [ "${lines[1]}" = "brew install --cask installed_package --force" ]
}

@test "cask inspect: returns FAILED_PRECONDITION without brew exec" {
    respond_to "which brew" "return 1"
    run cask inspect
    [ "$status" -eq $STATUS_FAILED_PRECONDITION ]
}

@test "cask inspect: returns OK if preconditions met" {
    run cask inspect
    [ "$status" -eq $STATUS_OK ]
}
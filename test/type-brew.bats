#!/usr/bin/env bats

. test/helpers.sh
brew () { . $BORK_SOURCE_DIR/types/brew.sh $*; }

setup () {
  respond_to "uname -s" "echo Darwin"
  respond_to "brew list --formula" "cat $fixtures/brew-list.txt"
  respond_to "brew outdated --formula" "cat $fixtures/brew-outdated.txt"
}

@test "brew status reports unsupported platform" {
  respond_to "uname -s" "echo Linux"
  run brew status something
  [ "$status" -eq $STATUS_UNSUPPORTED_PLATFORM ]
}

@test "brew status reports missing brew exec" {
  respond_to "which brew" "return 1"
  run brew status something
  [ "$status" -eq $STATUS_FAILED_PRECONDITION ]
}

@test "brew status reports a package is missing" {
  run brew status missing_package_is_missing
  [ "$status" -eq $STATUS_MISSING ]
}

@test "brew status reports a package is outdated" {
  run brew status outdated_package
  [ "$status" -eq $STATUS_OUTDATED ]
}

@test "brew status reports a package is current" {
  run brew status current_package
  [ "$status" -eq $STATUS_OK ]
  [ "${#lines[*]}" -eq 0 ]
}

@test "brew install runs 'install'" {
  run brew install missing_package_is_missing
  [ "$status" -eq 0 ]
  run baked_output
  [ "$output" = 'brew install --formula missing_package_is_missing' ]
}

@test "brew install runs 'install' with 'from'" {
  run brew install missing_package_is_missing --from=example_tap
  [ "$status" -eq 0 ]
  run baked_output
  echo $output
  [ "$output" = 'brew install --formula example_tap/missing_package_is_missing' ]
}

@test "brew install runs 'install' from HEAD" {
  run brew install missing_package_is_missing --HEAD
  [ "$status" -eq 0 ]
  run baked_output
  [ "$output" = 'brew install --formula missing_package_is_missing --HEAD --fetch-HEAD' ]
}

@test "brew upgrade runs 'upgrade'" {
  run brew upgrade outdated_package
  [ "$status" -eq 0 ]
  run baked_output
  [ "$output" = 'brew upgrade --formula outdated_package' ]
}

@test "brew upgrade runs 'upgrade' from HEAD" {
  run brew upgrade outdated_package --HEAD
  [ "$status" -eq 0 ]
  run baked_output
  [ "$output" = 'brew upgrade --formula outdated_package --fetch-HEAD' ]
}

@test "brew inspect: returns FAILED_PRECONDITION without brew exec" {
    respond_to "which brew" "return 1"
    run brew inspect
    [ "$status" -eq $STATUS_FAILED_PRECONDITION ]
}

@test "brew inspect: returns OK if preconditions met" {
    run brew inspect
    [ "$status" -eq $STATUS_OK ]
}

@test "brew remove runs 'remove'" {
  run brew remove unwanted_package
  [ "$status" -eq 0 ]
  run baked_output
  [ "$output" = 'brew remove --formula unwanted_package' ]
}

@test "brew remove runs 'remove' with 'from'" {
  run brew remove unwanted_package --from=example_tap
  [ "$status" -eq 0 ]
  run baked_output
  echo $output
  [ "$output" = 'brew remove --formula example_tap/unwanted_package' ]
}
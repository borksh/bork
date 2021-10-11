#!/usr/bin/env bats

. test/helpers.sh

dnf () { . $BORK_SOURCE_DIR/types/dnf.sh $*; }

setup () {
  respond_to "uname -s" "echo Linux"
  respond_to "rpm -qa" "cat $fixtures/rpm-qa.txt"
  respond_to "sudo dnf list updates" "cat $fixtures/dnf-list-updates.txt"
}

@test "dnf status reports incorrect platform" {
  respond_to "uname -s" "echo Darwin"
  run dnf status some_package
  [ "$status" -eq $STATUS_UNSUPPORTED_PLATFORM ]
}

@test "dnf status reports missing dnf" {
  respond_to "which dnf" "return 1"
  run dnf status some_package
  [ "$status" -eq $STATUS_FAILED_PRECONDITION ]
}

@test "dnf status reports a package is missing" {
  run dnf status missing_package
  [ "$status" -eq $STATUS_MISSING ]
}

@test "dnf status reports a package is outdated" {
  run dnf status outdated_package
  [ "$status" -eq $STATUS_OUTDATED ]
}

@test "dnf status reports a package is current" {
  run dnf status current_package
  [ "$status" -eq $STATUS_OK ]
}

@test "dnf install runs 'dnf install'" {
  run dnf install missing_package
  [ "$status" -eq $STATUS_OK ]
  run baked_output
  [ "$output" = 'sudo dnf -y install missing_package' ]
}

@test "dnf upgrade runs 'dnf install'" {
  run dnf upgrade outdated_package
  [ "$status" -eq $STATUS_OK ]
  run baked_output
  [ "$output" = 'sudo dnf -y install outdated_package' ]
}

@test "dnf remove runs 'dnf install'" {
  run dnf remove unwanted_package
  [ "$status" -eq $STATUS_OK ]
  run baked_output
  [ "$output" = 'sudo dnf -y remove unwanted_package' ]
}

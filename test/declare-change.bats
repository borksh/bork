#!/usr/bin/env bats

. test/helpers.sh

@test "did_install reflects \$performed_install" {
  bork_performed_install=1
  run did_install
  [ "$status" -eq 0 ]
  bork_performed_install=0
  run did_install
  [ "$status" -eq 1 ]
}

@test "did_upgrade reflects \$performed_upgrade" {
  bork_performed_upgrade=1
  run did_upgrade
  [ "$status" -eq 0 ]
  bork_performed_upgrade=0
  run did_upgrade
  [ "$status" -eq 1 ]
}

@test "did_update reflects all of install/upgrade/remove" {
  bork_performed_install=1
  run did_update
  [ "$status" -eq 0 ]
  bork_performed_install=0
  bork_performed_upgrade=1
  run did_update
  [ "$status" -eq 0 ]
  bork_performed_upgrade=0
  bork_performed_remove=1
  run did_update
  [ "$status" -eq 0 ]
  bork_performed_remove=0
  run did_update
  [ "$status" -eq 1 ]
}

@test "did_remove reflects \$performed_remove" {
  bork_performed_remove=1
  run did_remove
  [ "$status" -eq 0 ]
  bork_performed_remove=0
  run did_remove
  [ "$status" -eq 1 ]
}
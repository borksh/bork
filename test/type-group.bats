#!/usr/bin/env bats

. test/helpers.sh
group () { . $BORK_SOURCE_DIR/types/group.sh $*; }

setup () {
  respond_to "cat /etc/group" "echo 'root:x:0'; echo 'admin:x:50'"
  respond_to "dseditgroup -o read admin" "cat $fixtures/group-darwin.txt"
  respond_to "dseditgroup -o read custom" "return 64"
  respond_to "dscl . -list /Groups" "echo 'admin'; echo 'staff';"
}

@test "group status: returns FAILED_PRECONDITION when missing groupadd exec (Linux)" {
  respond_to "uname -s" "echo Linux"
  respond_to "which groupadd" "return 1"
  run group status foo
  [ "$status" -eq $STATUS_FAILED_PRECONDITION ]
}

@test "group status: returns FAILED_PRECONDITION when missing groupdel exec (Linux)" {
  respond_to "uname -s" "echo Linux"
  respond_to "which groupdel" "return 1"
  run group status foo
  [ "$status" -eq $STATUS_FAILED_PRECONDITION ]
}

@test "group status: returns FAILED_PRECONDITION when missing dseditgroup exec (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  respond_to "which dseditgroup" "return 1"
  run group status foo
  [ "$status" -eq $STATUS_FAILED_PRECONDITION ]
}

@test "group status: allow missing groupadd/groupdel on Darwin" {
  respond_to "uname -s" "echo Darwin"
  respond_to "which groupadd" "return 1"
  respond_to "which groupdel" "return 1"
  respond_to "which dseditgroup" "echo /usr/sbin/dseditgroup"
  run group status admin
  [ "$status" -eq $STATUS_OK ]
}

@test "group status: returns MISSING when group doesn't exist (Linux)" {
  respond_to "uname -s" "echo Linux"
  run group status custom
  [ "$status" -eq $STATUS_MISSING ]
}

@test "group status: returns MISSING when group doesn't exist (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run group status custom
  [ "$status" -eq $STATUS_MISSING ]
}

@test "group status: returns OK when group exists (Linux)" {
  respond_to "uname -s" "echo Linux"
  run group status admin
  [ "$status" -eq $STATUS_OK ]
}

@test "group status: returns OK when group exists (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run group status admin
  [ "$status" -eq $STATUS_OK ]
}

@test "group install: bakes 'groupadd' (Linux)" {
  respond_to "uname -s" "echo Linux"
  run group install custom
  [ "$status" -eq 0 ]
  run baked_output
  [ "${#lines[*]}" -eq 2 ]
  [ "${lines[1]}" = "groupadd custom" ]
}

@test "group remove: bakes 'groupdel' (Linux)" {
  respond_to "uname -s" "echo Linux"
  run group remove custom
  [ "$status" -eq 0 ]
  run baked_output
  [ "${#lines[*]}" -eq 2 ]
  [ "${lines[1]}" = "groupdel custom" ]
}

@test "group install: bakes 'dseditgroup create' (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run group install custom
  [ "$status" -eq 0 ]
  run baked_output
  [ "${#lines[*]}" -eq 2 ]
  [ "${lines[1]}" = "sudo dseditgroup -o create custom" ]
}

@test "group remove: bakes 'dseditgroup delete' (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run group remove custom
  [ "$status" -eq 0 ]
  run baked_output
  [ "${#lines[*]}" -eq 2 ]
  [ "${lines[1]}" = "sudo dseditgroup -o delete custom" ]
}

@test "group inspect: returns FAILED_PRECONDITION without dscl exec (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  respond_to "which dscl" "return 1"
  run group inspect
  [ "$status" -eq $STATUS_FAILED_PRECONDITION ]
}

@test "group inspect: returns OK if preconditions met (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run group inspect
  [ "$status" -eq $STATUS_OK ]
  [ "${lines[0]}" = "ok group admin" ]
}

@test "group inspect: returns list of groups (Linux)" {
  respond_to "uname -s" "echo Linux"
  run group inspect
  [ "$status" -eq $STATUS_OK ]
  [ "${lines[0]}" = "ok group root" ]
}
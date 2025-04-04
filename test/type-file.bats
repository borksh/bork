#!/usr/bin/env bats

. test/helpers.sh

file () { . $BORK_SOURCE_DIR/types/file.sh $*; }

setup () {
  readsum=$(eval $(md5cmd $platform Readme.md))
}

# -- without arguments -------------------------------
@test "file status: returns MISSING when file is missing" {
  respond_to "[ -f missing ]" "return 1"
  run file status missing Readme.md
  [ "$status" -eq $STATUS_MISSING ]
}

@test "file status: returns FAILED_ARGUMENTS when source file is missing" {
  run file status somefile missingfile
  [ "$status" -eq $STATUS_FAILED_ARGUMENTS ]
}

@test "file status: returns CONFLICT_UPGRADE when sum doesn't match" {
  respond_to "$(md5cmd $platform wrongfile)" "echo 123456"
  run file status wrongfile Readme.md
  [ "$status" -eq $STATUS_CONFLICT_UPGRADE ]
  expected="expected sum: $readsum"
  [[ ${lines[0]} == $expected ]]
  [[ ${lines[1]} == "received sum: 123456" ]]
}

@test "file status: returns OK when all is well" {
  respond_to "$(md5cmd $platform goodfile)" "echo $readsum"
  run file status goodfile Readme.md
  [ "$status" -eq $STATUS_OK ]
}

@test "file install: creates directory, copies file" {
  run file install path/to/target path/from/source
  [ "$status" -eq 0 ]
  run baked_output
  [ "${lines[0]}" = "mkdir -p path/to" ]
  [ "${lines[1]}" = "cp path/from/source path/to/target" ]
}

@test "file install: ignores directory if not present" {
  run file install target source
  [ "$status" -eq 0 ]
  run baked_output
  [ "${lines[0]}" = "cp source target" ]
}

@test "file remove: deletes file" {
  run file remove target source
  [ "$status" -eq 0 ]
  run baked_output
  [ "${lines[0]}" = "rm target" ]
}

# -- with permission argument ------------------------
@test "file status: returns MISMATCH_UPGRADE when target file has incorrect permissions" {
  respond_to "$(md5cmd $platform tfile)" "echo $readsum"
  respond_to "$(permission_cmd $platform) tfile" "echo 755"
  run file status tfile Readme.md --permissions=700
  [ "$status" -eq $STATUS_MISMATCH_UPGRADE ]
  [ "${lines[0]}" = "expected permissions: 700" ]
  [ "${lines[1]}" = "received permissions: 755" ]
}

@test "file install: sets permissions for file after copying" {
  run file install target path/from/source --permissions=700
  [ "$status" -eq 0 ]
  run baked_output
  [ "${lines[1]}" = "chmod 700 target" ]
}

# -- with owner argument -----------------------------
@test "file status: returns FAILED_ARGUMENT_PRECONDITION when target user doesn't exist" {
  respond_to "id -u kermit" "echo 'id: kermit: no such user'; return 1"
  run file status target Readme.md --owner=kermit
  [ "$status" -eq $STATUS_FAILED_ARGUMENT_PRECONDITION ]
  [ "${lines[0]}" = "unknown owner: kermit" ]
}

@test "file status: returns MISMATCH_UPGRADE when target file has incorrect owner" {
  respond_to "sudo $(md5cmd $platform target)" "echo $readsum"
  respond_to "sudo ls -l target" "echo -rw-r--r--  1 kermit  staff  4604"
  run file status target Readme.md --owner=bork
  [ "$status" -eq $STATUS_MISMATCH_UPGRADE ]
  [ "${lines[0]}" = "expected owner: bork" ]
  [ "${lines[1]}" = "received owner: kermit" ]
}

@test "file status: returns OK with owner and all is well" {
  respond_to "sudo $(md5cmd $platform target)" "echo $readsum"
  respond_to "sudo ls -l target" "echo -rw-r--r--  1 kermit  staff  4604"
  run file status target Readme.md --owner=kermit
  [ "$status" -eq $STATUS_OK ]
}

@test "file install: copies file as correct user" {
  run file install path/to/target path/from/source --owner=kermit
  [ "$status" -eq 0 ]
  run baked_output
  [ "${lines[0]}" = "sudo mkdir -p path/to" ]
  [ "${lines[1]}" = "sudo chown kermit path/to" ]
  [ "${lines[2]}" = "sudo cp path/from/source path/to/target" ]
  [ "${lines[3]}" = "sudo chown kermit path/to/target" ]
}

@test "file remove: removes file with sudo" {
  run file remove path/to/target path/from/source --owner=kermit
  [ "$status" -eq 0 ]
  run baked_output
  [ "${lines[0]}" = "sudo rm path/to/target" ]
}

# --- compile ----------------------------------------
@test "file compile: echoes base64 representation to screen" {
  run file compile path/to/target Readme.md
  [ "$status" -eq 0 ]
  expected="borkfiles__UmVhZG1lLm1kCg=\"$(cat Readme.md | base64)\""
  accum="${lines[2]}"
  line=2
  while [ "$line" -lt ${#lines[*]} ]; do
    (( line++ ))
    accum=$(echo "$accum"; echo "${lines[line]}")
  done
  [[ "$accum" = $expected ]]
}

@test "file compile: outputs warning to stderr on missing file" {
  run file compile target foo-missing
  [ "$status" -eq 1 ]
  [ "$output" = "fatal: file 'foo-missing' does not exist!" ]
}

is_compiled () { [ -n "$is_compiled" ]; }

@test "file status: if compiled, uses stored variable" {
  is_compiled=1
  borkfiles__cGF0aC9mcm9tL3NvdXJjZQo="$(cat Readme.md | base64)"
  respond_to "$(md5cmd $platform path/to/target)" "echo $readsum"
  run file status path/to/target path/from/source
  [ "$status" -eq $STATUS_OK ]
}

@test "file install: if compiled, uses stored variable" {
  is_compiled=1
  borkfiles__cGF0aC9mcm9tL3NvdXJjZQo="$(cat Readme.md | base64)"
  run file install path/to/target path/from/source
  [ "$status" -eq $STATUS_OK ]
  run baked_output
  expected="echo \"$borkfiles__cGF0aC9mcm9tL3NvdXJjZQo\" | base64 --decode > path/to/target"
  expected=$(echo $expected)
  [[ "${lines[1]}" = $expected ]]
}

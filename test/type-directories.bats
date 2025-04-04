#!/usr/bin/env bats

. test/helpers.sh
directory () { . $BORK_SOURCE_DIR/types/directory.sh "$@"; }

# these tests use live directories in a tempdir
baking_responder () { eval "$@"; }

setup () {
  tmpdir=$(mktemp -d -t bork-dirXXXXXX)
  cd $tmpdir
}
teardown () {
  rm -rf $tmpdir
}

mkdirs () {
  for d in $*; do mkdir -p $d; done
}

@test "directory: status returns OK if directory is present" {
  mkdirs foo
  run directory status foo
  [ "$status" -eq $STATUS_OK ]
}

@test "directory: status returns MISSING if directory isn't present" {
  run directory status foo
  [ "$status" -eq $STATUS_MISSING ]
}

@test "directory: status returns CONFLICT_CLOBBER if target is non-directory" {
  echo "FOO" > foo
  run directory status foo
  [ "$status" -eq $STATUS_CONFLICT_CLOBBER ]
  str_matches "${lines[0]}" "exists"
}

@test "directory: install creates target directory" {
  respond_to "uname -s" "echo Linux"
  run directory install foo
  [ "$status" -eq 0 ]
  run baked_output
  [ "${lines[1]}" = "install -C -d foo" ]
}

@test "directory: install uses correct syntax on Darwin" {
  respond_to "uname -s" "echo Darwin"
  run directory install foo
  [ "$status" -eq 0 ]
  run baked_output
  [ "${lines[1]}" = "install -d foo" ]
}

@test "directory: remove deletes target directory" {
  mkdir foo
  run directory remove foo
  [ "$status" -eq 0 ]
  run baked_output
  [ "${lines[0]}" = "rm -r \"foo\"" ]
}

@test "directory: handles directories with a space in the path" {
  mkdir "foo bar"
  run directory status "foo bar"
  [ "$status" -eq $STATUS_OK ]

  run directory remove "foo bar"
  run directory status "foo bar"
  [ "$status" -eq $STATUS_MISSING ]
}

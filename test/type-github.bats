#!/usr/bin/env bats

. test/helpers.sh
github () { . $BORK_SOURCE_DIR/types/github.sh $*; }

intercept_git () { echo "$*"; }
git_call="intercept_git"

@test "github status: handles implicit target" {
  run github status borksh/bork
  [ "$output" = "status https://github.com/borksh/bork.git" ]
}

@test "github status: handles explicit target" {
  run github status /Users/skylar/code/bork borksh/bork
  [ "$output" = "status /Users/skylar/code/bork https://github.com/borksh/bork.git" ]
}

@test "github status: handles --ssh argument" {
  run github status borksh/bork --ssh
  [ "$output" = "status git@github.com:borksh/bork.git" ]
}

@test "github compile: outputs git type via include_assertion" {
  operation="compile"
  gitfn=$(include_assertion git $BORK_SOURCE_DIR/types/git.sh)
  bag init compiled_types
  run github compile foo/bar
  [ "$status" -eq 0 ]
  [[ ${output} == "${gitfn}" ]]
}

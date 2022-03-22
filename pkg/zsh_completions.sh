#compdef bork

_bork () {
  if [ "${#words[@]}" -gt "2" ]; then
    _files
  else
    local -a borkcmds
    borkcmds=(
      "check:perform 'status' for a single command"
      "compile:compile the config file to a self-contained script output to STDOUT"
      "do:perform 'satisfy' for a single command"
      "satisfy:satisfy the config file's conditions if possible"
      "status:determine if the config file's conditions are met"
      "inspect:output a Bork config file based on a type's current configuration"
      "types:list types and their usage information"
      "docgen:generates documentation under docs/_types for newly-added types"
      "version:get the currently installed version of bork"
    )
    _describe 'bork' borkcmds
  fi
}

_bork
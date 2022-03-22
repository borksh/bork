#compdef bork

_bork_typelist () {
  BORK_SOURCE_DIR=$(dirname $(dirname $(realpath $(which bork))))
  typefiles=$()
  BORK_TYPES=()
  for type in $BORK_SOURCE_DIR/types/*.sh; do
    BORK_TYPES+=$(basename $type '.sh')
  done
}

_bork () {
  if [ "${#words[@]}" -gt "2" ]; then
    case ${words[2]} in
      status|satisfy|compile)
        _files ;;
      check|do)
        if [ "${#words[@]}" = "3" ]; then
          assertions=("ok")
          _describe 'bork' assertions
        elif [ "${#words[@]}" = "4" ]; then
          _bork_typelist
          _describe 'bork' BORK_TYPES
        else
          return
        fi ;;
      types|inspect)
        _bork_typelist
        _describe 'bork' BORK_TYPES ;;
      docgen|version)
        return ;;
      *)
        return ;;
    esac
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
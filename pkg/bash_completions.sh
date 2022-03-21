#/usr/bin/env bash

_bork_completions () {
  if [ "${#COMP_WORDS[@]}" -gt "1" ]; then
    return
  fi
  COMPREPLY=($(compgen -W "check compile do satisfy status inspect types docgen version" "${COMP_WORDS[1]}"))
}

complete -F _bork_completions bork
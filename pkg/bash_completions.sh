#/usr/bin/env bash

_bork_completions () {
  COMPREPLY=($(compgen -W "check compile do satisfy status inspect types docgen version" "${COMP_WORDS[1]}"))
}

complete -F _bork_completions bork
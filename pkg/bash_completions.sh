#/usr/bin/env bash

_bork_completions () {
  if [ "${#COMP_WORDS[@]}" -le "2" ]; then
    COMPREPLY=($(compgen -W "check compile do satisfy status inspect types docgen version" "${COMP_WORDS[1]}"))
  elif [ "${#COMP_WORDS[@]}" -gt "2" ]; then
    local IFS=$'\n'
    local LASTCHAR=' '

    COMPREPLY=($(compgen -o plusdirs -f \
        -- "${COMP_WORDS[COMP_CWORD]}"))

    if [ ${#COMPREPLY[@]} = 1 ]; then
        [ -d "$COMPREPLY" ] && LASTCHAR=/
        COMPREPLY=$(printf %q%s "$COMPREPLY" "$LASTCHAR")
    else
        for ((i=0; i < ${#COMPREPLY[@]}; i++)); do
            [ -d "${COMPREPLY[$i]}" ] && COMPREPLY[$i]=${COMPREPLY[$i]}/
        done
    fi
  fi
}

complete -o nospace -F _bork_completions bork
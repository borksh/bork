#/usr/bin/env bash

_bork_typelist () {
  BORK_SOURCE_DIR=$(dirname $(dirname $(realpath $(which bork))))
  typefiles=$()
  BORK_TYPES=""
  for type in $BORK_SOURCE_DIR/types/*.sh; do
    BORK_TYPES="$BORK_TYPES $(basename $type '.sh')"
  done
}

_bork_completions () {
  if [ "${#COMP_WORDS[@]}" -le "2" ]; then
    COMPREPLY=($(compgen -W "check compile do satisfy status inspect types docgen version" "${COMP_WORDS[1]}"))
  elif [ "${#COMP_WORDS[@]}" -gt "2" ]; then
    case ${COMP_WORDS[1]} in
      status|satisfy|compile)
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
        ;;
      check|do)
        if [ "${#COMP_WORDS[@]}" == "3" ]; then
          COMPREPLY='ok'
        elif [ "${#COMP_WORDS[@]}" == "4" ]; then
          _bork_typelist
          COMPREPLY=$(compgen -W "$BORK_TYPES" "${COMP_WORDS[3]}")
        else
          return
        fi ;;
      types|inspect)
        _bork_typelist
        COMPREPLY=$(compgen -W "$BORK_TYPES" "${COMP_WORDS[2]}") ;;
      docgen|version)
        return ;;
      *)
        return ;;
    esac
  fi
}

complete -o nospace -F _bork_completions bork
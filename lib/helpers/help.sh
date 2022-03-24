type_help () {
  if [ -s $1 ]; then
    desc=$(. $1 desc)
    i=0
    summary=
    usage=
    while read -r line; do
      [ "$i" -eq 0 ] && summary=$line || usage=$([ -n "$usage" ] && echo "$usage"; echo "$line")
      (( i ++ ))
    done <<< "$desc"
    echo "$(printf '%15s' $(basename $1 '.sh')): $summary"
    if [ -n "$usage" ]; then
      while read -r line; do
        echo "                 $line"
      done <<< "$usage"
    fi
  else
    ohno "undefined type: $(basename $1 '.sh')"
  fi
}
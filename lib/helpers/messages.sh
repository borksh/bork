think() {
  [ -n "$BORK_QUIET" ] && return 0;
  echo -n "$*";
}

tell() {
  [ -n "$BORK_QUIET" ] && return 0;
  echo "$*";
}

ohno() { echo "$*" 1>&2; }
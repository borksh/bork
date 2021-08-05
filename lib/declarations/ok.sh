_source_runner () {
  if is_compiled; then echo "$1"
  else echo ". $1"
  fi
}

_bork_check_failed=0
check_failed () { [ "$_bork_check_failed" -gt 0 ] && return 0 || return 1; }

_checked_len=0
_checking () {
  type=$1
  shift
  check_str="$type: $*"
  _checked_len=${#check_str}
  echo -n "$check_str"$'\r'
}
_checked () {
  report="$*"

  # We need to clear the current line with spaces so find out how wide the
  # report is, and pad with the difference between that and the equivalent
  # "checking" line.
  # add in 10 extra chars of padding, to account for potential color codes
  (( pad=$_checked_len - ${#report} + 10 ))
  i=1
  while [ "$i" -le $pad ]; do
    report+=" "
    (( i++ ))
  done
  echo "$report"
}

_conflict_approve () {
  if [ -n "$BORK_CONFLICT_RESOLVE" ]; then
    return $BORK_CONFLICT_RESOLVE
  fi
  echo
  echo "== Warning! Assertion: $*"
  echo "Attempting to satisfy has resulted in a conflict.  Satisfying this may overwrite data."
  _yesno "Do you want to continue?"
  return $?
}

_yesno () {
  answered=0
  answer=
  while [ "$answered" -eq 0 ]; do
    read -p "$* (yes/no) " answer
    if [[ "$answer" == 'y' || "$answer" == "yes" || "$answer" == "n" || "$answer" == "no" ]]; then
      answered=1
    else
      echo "Valid answers are: yes y no n" >&2
    fi
  done
  [[ "$answer" == 'y' || "$answer" == 'yes' ]]
}

_make_change () {
  change_type=$1
  _changes_expected "$change_type" "$assertion" "$argstr"
  eval "$(_source_runner $fn) $change_type $quoted_argstr"
  _changes_complete $? $change_type
  last_change_type=$change_type
}

assert () {
  assert_mode=$1
  shift
  assertion=$1
  shift
  _bork_check_failed=0
  _changes_reset
  fn=$(_lookup_type $assertion)
  if [ -z "$fn" ]; then
    echo "not found: $assertion" 1>&2
    return 1
  fi
  argstr=$*
  quoted_argstr=
  while [ -n "$1" ]; do
    quoted_argstr=$(echo "$quoted_argstr '$1'")
    shift
  done
  case $operation in
    echo) echo "$fn $argstr" ;;
    status)
      _checking "checking" $assertion $argstr
      output=$(eval "$(_source_runner $fn) status $quoted_argstr")
      status=$?
      _checked "$(_status_for $assert_mode $status): $assertion $argstr"
      [ "$status" -eq 1 ] && _bork_check_failed=1
      [ "$status" -ne 0 ] && [ -n "$output" ] && echo "$output"
      [ "$assert_mode" = 'no' ] && [ $status -eq $STATUS_MISSING ] && return 0
      return $status
      ;;
    satisfy)
      _checking "checking" $assertion $argstr
      status_output=$(eval "$(_source_runner $fn) status $quoted_argstr")
      status=$?
      _checked "$(_status_for $assert_mode $status): $assertion $argstr"
      case $status in
        0)
          [ $assert_mode = 'no' ] && _make_change 'remove'
          ;;
        1)
          _bork_check_failed=1
          echo "$status_output"
          ;;
        10)
          [ $assert_mode = 'ok' ] && _make_change 'install'
          ;;
        11|12|13)
          if [ $assert_mode = 'ok' ]; then
            echo "$status_output"
            _make_change 'upgrade'
          elif [ $assert_mode = 'no' ]; then
            _make_change 'remove'
          fi
          ;;
        20)
          echo "$status_output"
          _conflict_approve $assertion $argstr
          if [ "$?" -eq 0 ]; then
            echo "Resolving conflict..."
            [ $assert_mode = 'ok' ] && _make_change 'upgrade'
            [ $assert_mode = 'no' ] && _make_change 'remove'
          else
            echo "Conflict unresolved."
          fi
          ;;
        *)
          echo "-- sorry, bork doesn't handle this response yet"
          echo "$status_output"
          ;;
      esac
      if did_update; then
        echo "verifying $last_change_type: $assertion $argstr"
        output=$(eval "$(_source_runner $fn) status $quoted_argstr")
        status=$?
        if [ "$status" -gt 0 ] && [ "$assert_mode" = 'ok' ]; then
          echo "* $last_change_type failed"
          _checked "$(_status_for $assert_mode $status)"
          echo "$output"
        elif [ "$status" -ne "$STATUS_MISSING" ] && [ "$assert_mode" = 'no' ]; then
          echo "* $last_change_type failed"
          _checked "$(_status_for $assert_mode $status)"
          echo "$output"
        else
          echo "* success"
        fi
        return 1
      fi
      ;;
  esac
}

ok () {
  assert 'ok' $*
}

no () {
  assert 'no' $*
}
# TODO check --shell argument for existence of shell, presence in /etc/shells
# TODO need to check --groups to make sure they exist
# TODO ability to check group memberships on Darwin?
# TODO no useradd binary on Darwin

action=$1
handle=$2
shift 2

shell=$(arguments get shell $*)
groups=$(arguments get groups $*)
preserve_home=$(arguments get preserve-home $*)

user_get () {
  if baking_platform_is "Linux"; then
    row=$(bake cat /etc/passwd | grep -E "^$1:")
    stat=$?
  elif baking_platform_is "Darwin"; then 
    row=$(bake dscl . -list /Users | grep -E "^$1$")
    stat=$?
  fi
  echo $row
  return $stat
}

user_shell () {
  baking_platform_is "Linux" && current_shell=$(echo "$1" | cut -d: -f 7)
  baking_platform_is "Darwin" && current_shell=$(bake dscl . -read "/Users/$1" UserShell | sed -E 's/^UserShell: //g')
  if [ "$current_shell" != $2 ]; then
    echo $current_shell
    return 1
  fi
  return 0
}

user_groups () {
  current_groups=$(bake groups $1)
  baking_platform_is "Linux" && current_groups=$(echo "$current_groups" | cut -d: -f 2)
  missing_groups=
  expected_groups=$(IFS=','; echo $2)

  for group in $expected_groups; do
    echo "$current_groups" | grep -E "\b$group\b" > /dev/null
    if [ "$?" -gt 0 ]; then
      missing_groups=1
      echo $group
    fi
  done

  [ -n "$missing_groups" ] && return 1
  return 0
}

case $action in
  desc)
    echo "assert presence of a user on the system"
    echo "> user admin"
    echo "--shell=/bin/fish"
    echo "--groups=admin,deploy"
    ;;
  status)
    if baking_platform_is "Linux"; then
      needs_exec "useradd" || return $STATUS_FAILED_PRECONDITION
      needs_exec "userdel" || return $STATUS_FAILED_PRECONDITION
    elif baking_platform_is "Darwin"; then
      needs_exec "dscl" || return $STATUS_FAILED_PRECONDITION
    else
      return $STATUS_UNSUPPORTED_PLATFORM
    fi

    row=$(user_get $handle)
    [ "$?" -gt 0 ] && return $STATUS_MISSING

    if [ -n "$shell" ]; then
      msg=$(user_shell "$row" $shell)
      if [ "$?" -gt 0 ]; then
        echo "--shell: expected $shell; is $msg"
        mismatched=1
      fi
    fi

    if [ -n "$groups" ]; then
      msg=$(user_groups $handle $groups)
      if [ "$?" -gt 0 ]; then
        echo "--groups: expected $groups; missing $(echo $msg)"
        partial=1
      fi
    fi
    [ -n "$mismatched" ] && return $STATUS_MISMATCH_UPGRADE
    [ -n "$partial" ] && return $STATUS_PARTIAL
    return 0 ;;

  install)
    if baking_platform_is "Linux"; then
      args="-m"
      [ -n "$shell" ] && args="$args --shell $shell"
      [ -n "$groups" ] && groups_list=(${groups//,/ }) && args="$args --groups $groups"
      [[ -n "$groups_list" && "${groups_list[0]}" == "$handle" ]] && args="$args -g $handle"
      bake useradd $args $handle
    elif baking_platform_is "Darwin"; then
      # TODO add user on Darwin
      echo "not yet implemented"
    fi
    ;;

  upgrade)
    if [[ -n ${shell} ]] \
        && ! user_shell "$(user_get "${handle}")" "${shell}"; then
      bake chsh -s $shell $handle
    fi
    missing=$(user_groups $handle $groups)
    if [ "$?" -gt 0 ]; then
      groups_to_create=$(IFS=','; echo $missing)
      for group in $groups_to_create; do
        if baking_platform_is "Linux"; then
          bake adduser $handle $group
        elif baking_platform_is "Darwin"; then
          bake sudo dseditgroup -o edit -a $handle -t user $group
        fi
      done
    fi
    ;;

  remove)
    if [ -z "$preserve_home" ]; then
      if baking_platform_is "Linux"; then
        bake userdel -r $handle
      elif baking_platform_is "Darwin"; then
        home_directory=$(bake dscl . -read "/Users/$handle" NFSHomeDirectory | sed -E 's/^NFSHomeDirectory: //g')
        bake sudo dscl . -delete "/Users/$handle"
        bake rm -r "$home_directory"
      fi
    else
      if baking_platform_is "Linux"; then
        bake userdel $handle
      elif baking_platform_is "Darwin"; then
        bake sudo dscl . -delete "/Users/$handle"
      fi
    fi
    ;;

  *) return 1 ;;
esac

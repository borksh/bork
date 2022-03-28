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
real_name=$(arguments get real-name $*)

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
      release=$(get_baking_platform_release | cut -d. -f 1)
      if [ "$release" -ge "14" ]; then
        needs_exec "sysadminctl" || return $STATUS_FAILED_PRECONDITION
      fi
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
      release=$(get_baking_platform_release | cut -d. -f 1)
      if [ "$release" -ge "14" ]; then
        # we can use sysadminctl
        args="$handle -password -"
        [ -n "$real_name" ] && args="$args -fullName $real_name"
        bake sudo sysadminctl -addUser $args
      else
        bake sudo dscl . -create "/Users/$handle"
        maxid=$(bake dscl . -list /Users UniqueID | awk 'BEGIN { max = 500; } { if ($2 > max) max = $2; } END { print max + 1; }')
        newid=$((maxid+1))
        bake sudo dscl . -create "/Users/$handle" UniqueID "$newid"
        bake sudo dscl . -create "/Users/$handle" PrimaryGroupID 20
        bake sudo dscl . -create "/Users/$handle" NFSHomeDirectory "/Users/$handle"
        bake sudo dscl . -passwd "/Users/$handle"
        [ -n "$real_name" ] && bake sudo dscl . -create "/Users/$handle" RealName "$real_name" || bake sudo dscl . -create "/Users/$handle" RealName "$handle"
        bake sudo cp -R "/System/Library/User Template/English.lproj" "/Users/$handle"
        bake sudo chown -R "$handle":staff "/Users/$handle"
        if [[ "$(bake sw_vers -productVersion)" != 10.[0-5].* ]]; then
          # Set ACL on Drop Box in 10.6 and later
          bake sudo chmod +a "user:$handle allow list,add_file,search,delete,add_subdirectory,delete_child,readattr,writeattr,readextattr,writeextattr,readsecurity,writesecurity,chown,file_inherit,directory_inherit" "/Users/$handle/Public/Drop Box"
        fi
      fi
      [ -n "$shell" ] && bake sudo dscl . -create "/Users/$handle" UserShell "$shell" || bake sudo dscl . -create "/Users/$handle" UserShell /bin/zsh
      if [ -n "$groups" ]; then
        expected_groups=$(IFS=','; echo $groups)
        for group in $expected_groups; do
          bake sudo dseditgroup -o edit -a $handle -t user $group
        done
      fi
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

  inspect)
    if baking_platform_is "Linux"; then
      users=$(bake cat /etc/passwd)
      while IFS= read -r user; do
        echo "ok user $user" | cut -d: -f 1
      done <<< "$users"
    elif baking_platform_is "Darwin"; then
      needs_exec "dscl" || return $STATUS_FAILED_PRECONDITION
      users=$(bake dscl . -list /Users)
      while IFS= read -r user; do
        # remove system users
        echo $user | grep -E '^_' >/dev/null
        [ $? -gt 0 ] && echo "ok user $user"
      done <<< "$users"
    else
      # we don't know how to do this on other platforms
      return $STATUS_UNSUPPORTED_PLATFORM
    fi ;;

  *) return 1 ;;
esac

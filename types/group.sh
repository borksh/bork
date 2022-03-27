action=$1
groupname=$2
shift 2

case $action in
  desc)
    echo "asserts presence of a user group"
    echo "> group admin"
    ;;
  status)
    if baking_platform_is "Linux"; then
      needs_exec groupadd || return $STATUS_FAILED_PRECONDITION
      needs_exec groupdel || return $STATUS_FAILED_PRECONDITION

      bake cat /etc/group | grep -E "^$groupname:"
      [ "$?" -gt 0 ] && return $STATUS_MISSING
    elif baking_platform_is "Darwin"; then
      needs_exec "dseditgroup" || return $STATUS_FAILED_PRECONDITION
      bake dseditgroup -o read "$groupname" 2>/dev/null
      [ "$?" -gt 0 ] && return $STATUS_MISSING
    else
      # we don't know how to do this on other platforms
      return $STATUS_UNSUPPORTED_PLATFORM
    fi
    return $STATUS_OK ;;

  install)
    if baking_platform_is "Linux"; then
      bake groupadd $groupname
    elif baking_platform_is "Darwin"; then
      bake sudo dseditgroup -o create $groupname
    fi ;;

  remove)
    if baking_platform_is "Linux"; then
      bake groupdel $groupname
    elif baking_platform_is "Darwin"; then
      bake sudo dseditgroup -o delete $groupname
    fi ;;

  *) return 1 ;;
esac

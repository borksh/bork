
action=$1
name=$2
shift 2
case $action in
  desc)
    echo "asserts packages installed via dnf on Fedora, CentOS or RedHat"
    echo "* dnf package-name"
    ;;
  status)
    baking_platform_is "Linux" || return $STATUS_UNSUPPORTED_PLATFORM
    needs_exec "dnf" 0
    [ "$?" -gt 0 ] && return $STATUS_FAILED_PRECONDITION

    echo "$(bake rpm -qa)" | grep "^$name"
    [ "$?" -gt 0 ] && return $STATUS_MISSING

    echo "$(bake sudo dnf list updates)" | grep "^$name"
    [ "$?" -eq 0 ] && return $STATUS_OUTDATED
    return $STATUS_OK
    ;;

  install|upgrade)
    bake sudo dnf -y install $name
    ;;

  remove)
    bake sudo dnf -y remove $name
    ;;
    
  *) return 1 ;;
esac

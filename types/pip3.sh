# TODO --sudo flag
# TODO versions
# TODO update

action=$1
name=$2
shift 2

case $action in
  desc)
    echo "asserts presence of packages installed via pip"
    echo "> pip3 pygments"
    ;;
  status)
    needs_exec "pip3" || return $STATUS_FAILED_PRECONDITION
    pkgs=$(bake pip3 list)
    if ! str_matches "$pkgs" "^$name"; then
      return $STATUS_MISSING
    fi
    return 0 ;;
  install)
    bake pip3 install "$name"
    ;;
esac


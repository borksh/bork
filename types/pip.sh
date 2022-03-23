# TODO --sudo flag
# TODO versions
# TODO update

action=$1
name=$2
shift 2
sudo=$(arguments get sudo $*)

case $action in
  desc)
    echo "asserts presence of packages installed via pip"
    echo "> pip pygments"
    echo "--sudo            (install with sudo)"
    ;;
  status)
    needs_exec "pip" || return $STATUS_FAILED_PRECONDITION
    pkgs=$(PIP_FORMAT=legacy bake pip list)
    if ! str_matches "$pkgs" "^$name"; then
      return $STATUS_MISSING
    fi
    return 0 ;;
  install)
    if [ -n "$sudo" ]; then
      bake sudo pip install "$name"
    else
      bake pip install "$name"
    fi
    ;;
  remove)
    if [ -n "$sudo" ]; then
      bake sudo pip uninstall "$name"
    else
      bake pip uninstall "$name"
    fi
    ;;
esac


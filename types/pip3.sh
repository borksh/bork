# TODO --sudo flag
# TODO versions
# TODO update

action=$1
name=$2
shift 2
sudo=$(arguments get sudo $*)

case $action in
  desc)
    echo "asserts presence of packages installed via pip3"
    echo "> pip3 pygments"
    echo "--sudo            (install with sudo)"
    ;;
  status)
    needs_exec "pip3" || return $STATUS_FAILED_PRECONDITION
    pkgs=$(bake pip3 list)
    if ! str_matches "$pkgs" "^$name"; then
      return $STATUS_MISSING
    fi
    return 0 ;;
  install)
    if [ -n "$sudo" ]; then
      bake sudo pip3 install "$name"
    else
      bake pip3 install "$name"
    fi
    ;;
  inspect)
    needs_exec "pip3" || return $STATUS_FAILED_PRECONDITION
    installed=$(bake pip3 list --format freeze --not-required)
    while IFS= read -r pkg; do
        echo "ok pip3 $pkg" | sed -E 's/==[0-9\.]+$//g'
    done <<< "$installed"
    ;;
  remove)
    if [ -n "$sudo" ]; then
      bake sudo pip3 uninstall "$name"
    else
      bake pip3 uninstall "$name"
    fi
    ;;
esac


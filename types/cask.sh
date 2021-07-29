action=$1
name=$2
shift 2
appdir=$(arguments get appdir $*)

case $action in
  desc)
    echo "asserts presence of apps installed via caskroom.io on macOS"
    echo "* cask app-name         (installs cask)"
    echo "--appdir=/Applications  (changes symlink path)"
    ;;

  status)
    baking_platform_is "Darwin" || return $STATUS_UNSUPPORTED_PLATFORM
    needs_exec "brew" || return $STATUS_FAILED_PRECONDITION
    bake brew --version > /dev/null
    [ "$?" -gt 0 ] && return $STATUS_FAILED_PRECONDITION

    list=$(bake brew list --cask)
    echo "$list" | grep -E "^$name$" > /dev/null
    [ "$?" -gt 0 ] && return $STATUS_MISSING

    info=$(bake brew info --cask $name)
    echo "$info" | grep 'Not installed' > /dev/null
    # TODO replace with perhaps "OUTDATED_CLOBBER" ?
    [ "$?" -eq 0 ] && return $STATUS_OUTDATED

    return 0 ;;

  install)
    if [ -n "$appdir"  ]; then
      bake brew install --cask $name --appdir=$appdir
    else
      bake brew install --cask $name
    fi
    ;;

  upgrade)
    # TODO move rm statement to remove action with clobber
    bake rm -rf "/usr/local/Caskroom/$name"
    if [ -n "$appdir" ]; then
      bake brew install --cask $name --appdir=$appdir --force
    else
      bake brew install --cask $name --force
    fi
    ;;

  inspect)
    baking_platform_is "Darwin" || return $STATUS_UNSUPPORTED_PLATFORM
    needs_exec "brew" || return $STATUS_FAILED_PRECONDITION
    installed=$(bake brew list --cask)
    while IFS= read -r cask; do
        echo "ok cask $cask"
    done <<< "$installed"
    ;;

  *) return 1 ;;
esac

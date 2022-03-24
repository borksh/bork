action=$1
target=$2
source=$3

case "$action" in
  desc)
    echo "assert presence and target of a symlink"
    echo "> symlink .vimrc ~/code/dotfiles/configs/vimrc"
    ;;

  status)
    bake [ ! -e "$target" ] && return $STATUS_MISSING
    if bake [ ! -h "$target" ]; then
      tell "not a symlink: $target"
      return $STATUS_CONFLICT_CLOBBER
    else
      existing_source=$(bake readlink \"$target\")
      if [ "$existing_source" != "$source" ]; then
        tell "received source for existing symlink: $existing_source"
        tell "expected source for symlink: $source"
        return $STATUS_MISMATCH_UPGRADE
      fi
    fi
    return $STATUS_OK
    ;;

  install|upgrade)
    bake ln -sf "$source" "$target" ;;

  *) return 1;;
esac

# TODO install - test for necessity of 'sudo' prefix
# TODO --version - support for status, install, update
# TODO gem flags - figure out convention to pass through, similar to brew?

action=$1
gemname=$2
shift 2

case $action in
  desc)
    echo "asserts the presence of a gem in the environment's ruby"
    echo "> gem bundler"
    ;;
  status)
    needs_exec "gem" || return $STATUS_FAILED_PRECONDITION
    gems=$(bake gem list)
    if ! str_matches "$gems" "^$gemname"; then
      return $STATUS_MISSING
    fi
    outdated_gems=$(bake gem outdated)
    if str_matches "$outdated_gems" "^$gemname"; then
      return $STATUS_OUTDATED
    fi
    return 0 ;;
  install)
    bake sudo gem install "$gemname"
    ;;
  upgrade)
    bake sudo gem update "$gemname"
    ;;
  inspect)
    needs_exec "gem" || return $STATUS_FAILED_PRECONDITION
    installed=$(bake gem list --no-versions -q)
    while IFS= read -r gem; do
        echo "ok gem $gem"
    done <<< "$installed"
    ;;
  remove)
    bake sudo gem uninstall "$gemname"
    ;;
esac

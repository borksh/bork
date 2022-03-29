action=$1
name="$(echo $2 | awk '{print tolower($0)}')"
shift 2

case $action in
    desc)
        echo "asserts a homebrew formula repository has been tapped"
        echo "does NOT assert the updated-ness of a tap's formula - use \`ok brew\`"
        echo "> brew-tap homebrew/games    (taps homebrew/games)"
    ;;

    status)
        baking_platform_is "Darwin" || return $STATUS_UNSUPPORTED_PLATFORM
        needs_exec "brew" || return $STATUS_FAILED_PRECONDITION
        list=$(bake brew tap)
        echo "$list" | grep -E "$name$" > /dev/null
        [ "$?" -gt 0 ] && return $STATUS_MISSING
        return $STATUS_OK ;;

    install)
        bake brew tap $name
        ;;

    inspect)
        # TODO: make this check if the tap comes from anywhere except GitHub
        baking_platform_is "Darwin" || return $STATUS_UNSUPPORTED_PLATFORM
        needs_exec "brew" || return $STATUS_FAILED_PRECONDITION
        installed=$(bake brew tap)
        while IFS= read -r tap; do
            echo "ok brew-tap $tap"
        done <<< "$installed"
        ;;

    remove)
        bake brew untap $name
        ;;

    *) return 1 ;;
esac

action=$1
name="$(echo $2 | awk '{print tolower($0)}')"
shift 2
pin=$(arguments get pin $*)

case $action in
    desc)
        echo "asserts a homebrew formula repository has been tapped"
        echo "does NOT assert the updated-ness of a tap's formula - use \`ok brew\`"
        echo "> brew-tap homebrew/games    (taps homebrew/games)"
        echo "--pin                        (pins the formula repository)"
    ;;

    status)
        baking_platform_is "Darwin" || return $STATUS_UNSUPPORTED_PLATFORM
        needs_exec "brew" || return $STATUS_FAILED_PRECONDITION
        list=$(bake brew tap)
        echo "$list" | grep -E "$name$" > /dev/null
        [ "$?" -gt 0 ] && return $STATUS_MISSING
        pinlist=$(bake brew tap --list-pinned)
        echo "$pinlist" | grep -E "$name$" > /dev/null
        pinstatus=$?
        if [ -n "$pin" ]; then
            [ "$pinstatus" -gt 0 ] && return $STATUS_PARTIAL
        else
            [ "$pinstatus" -eq 0 ] && return $STATUS_PARTIAL
        fi
        return $STATUS_OK ;;

    install)
        bake brew tap $name
        if [ -n "$pin" ]; then
            bake brew tap-pin $name
        fi
        ;;

    upgrade)
        if [ -n "$pin" ]; then
            bake brew tap-pin $name
        else
            bake brew tap-unpin $name
        fi
        ;;

    inspect)
        # TODO: make this check if the tap comes from anywhere except GitHub
        # and also check for pinning
        baking_platform_is "Darwin" || return $STATUS_UNSUPPORTED_PLATFORM
        needs_exec "brew" || return $STATUS_FAILED_PRECONDITION
        installed=$(bake brew tap)
        while IFS= read -r tap; do
            echo "ok brew-tap $tap"
        done <<< "$installed"
        ;;

    *) return 1 ;;
esac

action=$1
targetfile=$2
sourceurl=$3
shift 3
size=$(arguments get size $*)

case "$action" in
    desc)
        echo "assert the presence & comparisons of a file to a URL"
        echo "> download ~/file.zip \"http://example.com/file.zip\""
        echo "--size                (compare size to Content-Length at URL)"
        ;;

    status)
        bake [ -f "\"$targetfile\"" ] || return $STATUS_MISSING

        if [ -n "$size" ]; then
            fileinfo=$(bake ls -al "\"$targetfile\"")
            sourcesize=$(echo "$fileinfo" | tr -s ' ' | cut -d' ' -f5)
            remoteinfo=$(bake $(http_head_cmd "$sourceurl"))
            remotesize=$(http_header "Content-Length" "$remoteinfo")
            remotesize=${remotesize%%[^0-9]*}
            if [ "$sourcesize" != "$remotesize" ]; then
                tell "expected size: $remotesize bytes"
                tell "received size: $localsize bytes"
                return $STATUS_CONFLICT_UPGRADE
            fi
        fi
        return $STATUS_OK
    ;;

    install|upgrade)
        bake $(http_get_cmd "$sourceurl" "$targetfile")
    ;;

    remove)
        ohno "remove is not possible on download type"
        ohno "use file type to assert absence of a file"
        return 1
    ;;

    *) return 1 ;;
esac

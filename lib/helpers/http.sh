has_curl () {
    needs_exec "curl"
}

http_head_cmd () {
    url=$1
    shift 1
    has_curl
    if [ "$?" -eq 0 ]; then
        echo "curl -sIL \"$url\""
    else
        echo "curl not found; wget support not implemented yet"
        return 1
    fi
}

http_header () {
    header=$1
    headers=$2
    echo "$headers" | grep "$header" | tr -s ' ' | cut -d' ' -f2 | tail -1
}

http_get_cmd () {
    url=$1
    target=$2
    has_curl
    if [ "$?" -eq 0 ]; then
        echo "curl -soL \"$target\" \"$url\" &> /dev/null"
    else
        echo "curl not found; wget support not implemented yet"
        return 1
    fi
}

#!/usr/bin/env bats

. test/helpers.sh

@test "http_head_cmd: with curl performs a head request" {
    respond_to "which curl" "echo /usr/bin/curl"
    url="https://foo.com"
    respond_to "curl -sIL \"https://foo.com\"" "cat $fixtures/http-head-curl.txt"
    run http_head_cmd "$url"
    [ "$status" -eq 0 ]
    [[ 'curl -sIL "https://foo.com"' == $output ]]
}

@test "http_head_cmd: with curl follows redirects" {
    respond_to "which curl" "echo /usr/bin/curl"
    url="https://bar.com"
    respond_to "curl -sIL \"https://bar.com\"" "cat $fixtures/http-head-curl-redir.txt"
    run http_head_cmd "$url"
    [ "$status" -eq 0 ]
    [[ 'curl -sIL "https://bar.com"' == $output ]]
}

@test "http_header: extracting a header value" {
    input=$(cat "$fixtures/http-head-curl.txt")
    run http_header "Content-Length" "$input"
    [ "312" -eq $output ]
}

@test "htpp_get: getting a file" {
    url="https://foo.com/bar"
    target="/boo/baz"
    run http_get_cmd "$url" "$target"
    [ "$status" -eq 0 ]
    [[ "curl -sLo \"$target\" \"$url\" &> /dev/null" == $output ]]
}

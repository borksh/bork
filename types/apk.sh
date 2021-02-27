#!/bin/bash

action=$1
name=$2
shift 2

case "${action}" in
  desc)
    printf '%s\n' \
      'asserts presence of packages installed via apk (Alpine Package Manager)' \
      '* apk package-name    (install/upgrade given package)'
    ;;
  status)
    needs_exec "apk" || return "${STATUS_FAILED_PRECONDITION}"

    bake apk info --installed "${name}" || return "${STATUS_MISSING}"
    version=$(bake apk version)
    str_matches "$version" "^${name}-[0-9]+\.[0-9]+" && return "${STATUS_OUTDATED}"
    return "${STATUS_OK}"
    ;;
  install|upgrade)
    bake sudo apk add "${name}"
    ;;
  delete)
    bake sudo apk del "${name}"
    ;;
  *) return 1 ;;
esac

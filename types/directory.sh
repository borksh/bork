action=$1
dir=$2
shift 2

owner=$(arguments get owner $*)
group=$(arguments get group $*)
mode=$(arguments get mode $*)

target_platform=$(get_baking_platform)

case "$action" in
  desc)
    printf '%s\n' \
      'asserts presence of a directory' \
      '* directory path [options]' \
      '--owner=user-name' \
      '--group=group-name' \
      '--mode=mode' \
      '> directory ~/.ssh --mode=700'
    ;;

  status)
    bake "[ -e \"${dir}\" ]" || return $STATUS_MISSING
    bake "[ -d \"${dir}\" ]" || {
      echo "target exists as non-directory"
      return $STATUS_CONFLICT_CLOBBER
    }

    mismatch=false
    if [[ -n ${owner} || -n ${group} || -n ${mode} ]]; then
      dir_stat=($(bake $(permission_cmd_dir $target_platform) "${dir}"))

      if [[ -n ${owner} && ${dir_stat[0]} != ${owner} ]]; then
        printf '%s owner: %s\n' \
          'expected' "${owner}" \
          'received' "${dir_stat[0]}"
        mismatch=true
      fi

      if [[ -n ${group} && ${dir_stat[1]} != ${group} ]]; then
        printf '%s group: %s\n' \
          'expected' "${group}" \
          'received' "${dir_stat[1]}"
        mismatch=true
      fi

      if [[ -n ${mode} && ${dir_stat[2]} != ${mode} ]]; then
        printf '%s mode: %s\n' \
          'expected' "${mode}" \
          'received' "${dir_stat[2]}"
        mismatch=true
      fi
    fi

    if ${mismatch}; then
      return "${STATUS_MISMATCH_UPGRADE}"
    fi

    return "${STATUS_OK}"
    ;;

  install|upgrade)
    if baking_platform_is "Darwin"; then
      inst_cmd=( install -d )
    else
      inst_cmd=( install -C -d )
    fi
    [[ -z ${owner} && -z ${group} ]] || inst_cmd=( sudo "${inst_cmd[@]}" )
    [[ -z ${owner} ]] || inst_cmd+=( -o "${owner}" )
    [[ -z ${group} ]] || inst_cmd+=( -g "${group}" )
    [[ -z ${mode} ]] || inst_cmd+=( -m "${mode}" )
    bake "${inst_cmd[@]}" "${dir}"
    ;;

  remove)
    bake "rm -r \"${dir}\""
    ;;

  *) return 1 ;;
esac

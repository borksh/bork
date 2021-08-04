#!/usr/bin/env bats

. test/helpers.sh

pipsi_global_bin_dir="/usr/local/bin"
pipsi_global_home="/usr/local/lib/pipsi"

pipsi() { . $BORK_SOURCE_DIR/types/pipsi.sh $*; }

setup() {
  respond_to 'pipsi list' "cat $fixtures/pipsi-list.txt"
}

# tests for pipsi bootstraping itself

@test "pipsi status (no-pkg) returns OK when pipsi is available" {
  respond_to 'which pipsi' "echo ${HOME}/.local/bin/pipsi; return 0"
  respond_to 'type -ap pipsi' "echo ${HOME}/.local/bin/pipsi; return 0"
  run pipsi status
  (( status == STATUS_OK ))
  [[ -z ${output} ]]
}

@test "pipsi status global (no-pkg) returns OK when global pipsi is available" {
  mock_which="echo ${pipsi_global_bin_dir}/pipsi"
  respond_to 'which pipsi' "${mock_which}"
  respond_to 'type -ap pipsi' "${mock_which}"

  run pipsi status --global
  (( status == STATUS_OK ))
  [[ -z ${output} ]]
}

@test "pipsi status global (no-pkg) returns OK when pipsi is installed as both local and global" {
  local_pipsi="${HOME}/.local/bin/pipsi"
  global_pipsi="${pipsi_global_bin_dir}/pipsi"
  respond_to 'which pipsi' "echo ${local_pipsi}; return 0"
  respond_to 'type -ap pipsi' "echo ${local_pipsi}; echo ${global_pipsi}"

  run pipsi status --global
  (( status == STATUS_OK ))
  [[ -z ${output} ]]
}

@test "pipsi status (no-pkg) returns MISSING when pipsi is missing" {
  respond_to 'which pipsi' 'return 1'
  run pipsi status
  (( status == STATUS_MISSING ))
}

@test "pipsi status (no-pkg) returns MISSING when local pipsi is missing" {
  respond_to 'which pipsi' "echo ${pipsi_global_bin_dir}/pipsi; return 0"
  run pipsi status
  (( status == STATUS_MISSING ))
  [[ -z ${output} ]]
}

@test "pipsi status global (no-pkg) returns MISSING when global pipsi is missing" {
  respond_to 'which pipsi' "echo ${HOME}/.local/bin/pipsi; return 0"
  run pipsi status --global
  (( status == STATUS_MISSING ))
  [[ -z ${output} ]]
}

@test "pipsi status (no-pkg) returns FAILED_PRECONDITION when python 3 is missing" {
  respond_to 'which python3' 'return 1'
  run pipsi status
  (( status == STATUS_FAILED_PRECONDITION ))
}

@test "pipsi status (no-pkg) returns FAILED_PRECONDITION when pipsi and curl are missing" {
  respond_to 'which pipsi' 'return 1'
  respond_to 'which curl' 'return 1'

  run pipsi status
  (( status == STATUS_FAILED_PRECONDITION ))
}

@test "pipsi status (no-pkg) returns FAILED_PRECONDITION when pipsi and git are missing" {
  respond_to 'which pipsi' 'return 1'
  respond_to 'which git' 'return 1'

  run pipsi status
  (( status == STATUS_FAILED_PRECONDITION ))
}

@test "pipsi install (no-pkg) bootstraps itself" {
  run pipsi install
  (( status == 0 ))
  run baked_output
  [[ ${output} =~ curl\ .*get-pipsi\.py ]]
  # should not check if already installed (bork type already does that)
  [[ ${output} =~ --ignore-existing ]]
  # should be installed from git master
  [[ ${output} =~ 'git+https://github.com/mitsuhiko/pipsi.git#egg=pipsi' ]]
}

@test "pipsi install (no-pkg) upgrades pip and setuptools after install" {
  run pipsi install
  run baked_output
  [[ ${output} =~ 'pip install --upgrade pip setuptools' ]]
}

@test "pipsi install global (no-pkg) bootstraps itself globally" {
  respond_to "test -w ${pipsi_global_bin_dir}/" 'return 0'
  respond_to "test -w ${pipsi_global_home}/" 'return 0'

  run pipsi install --global
  (( status == 0 ))
  run baked_output
  [[ ${output} =~ curl\ .*get-pipsi\.py ]]
  [[ ${output} =~ '|  python3' ]]
  [[ ${output} =~ --bin-dir=${pipsi_global_bin_dir} ]]
  [[ ${output} =~ --home=${pipsi_global_home} ]]
  # should not check if already installed (bork type already does that)
  [[ ${output} =~ --ignore-existing ]]
}

@test "pipsi install global (no-pkg) uses sudo if necessary to write to target dirs" {
  respond_to "test -w ${pipsi_global_bin_dir}/" 'return 1'
  respond_to "test -w ${pipsi_global_home}/" 'return 0'

  run pipsi install --global
  (( status == 0 ))
  run baked_output
  [[ ${output} =~ curl\ .*get-pipsi\.py ]]
  [[ ${output} =~ '| sudo python3' ]]
}

@test "pipsi upgrade (no-pkg) upgrades itself" {
  run pipsi upgrade
  (( status == 0 ))
  run baked_output
  [[ ${output} =~ 'pipsi upgrade pipsi' ]]
}

@test "pipsi delete (no-pkg) removes itself" {
  run pipsi delete
  (( status == 0 ))
  run baked_output
  [[ ${output} =~ 'pipsi uninstall pipsi' ]]
}

@test "pipsi remove (no-pkg) removes itself" {
  run pipsi remove
  (( status == 0 ))
  run baked_output
  [[ ${output} =~ 'pipsi uninstall pipsi' ]]
}

# tests for pipsi installing packages

@test "pipsi status returns FAILED_PRECONDITION when pipsi is missing" {
  respond_to 'which pipsi' 'return 1'
  run pipsi status something
  (( status == STATUS_FAILED_PRECONDITION ))
}

@test "pipsi status returns MISSING when package is not installed" {
  run pipsi status missing_package_is_missing
  (( status == STATUS_MISSING ))
}

@test "pipsi status returns OK when package is installed and current" {
  run pipsi status current_package
  (( status == STATUS_OK ))
}

@test "pipsi status returns OUTDATED when package is installed but outdated" {
  # check for outdated needs to run `pip` directly so hardcodes default
  # path to pipsi virtualenvs
  pip="${HOME}/.local/venvs/outdated_package/bin/pip"
  respond_to "${pip} list --outdated --format=legacy" \
    'echo \"outdated_package (1.1.0) - Latest: 1.2.0 [wheel]\"'

  run pipsi status outdated_package
  (( status == STATUS_OUTDATED ))
}

@test "pipsi status global runs 'list' with appropriate options" {
  run pipsi status something --global
  run baked_output
  [[ ${lines[${#lines[@]}-1]} =~ ^pipsi ]]
  [[ ${lines[${#lines[@]}-1]} =~ --bin-dir=${pipsi_global_bin_dir} ]]
  [[ ${lines[${#lines[@]}-1]} =~ --home=${pipsi_global_home} ]]
  [[ ${lines[${#lines[@]}-1]} =~ list ]]
}

@test "pipsi install runs 'install pkg'" {
  run pipsi install missing_package_is_missing
  (( status == 0 ))
  run baked_output
  [[ ${output} =~ 'pipsi install missing_package_is_missing' ]]
}

@test "pipsi install upgrades pip and setuptools after install" {
  run pipsi install missing_package_is_missing
  run baked_output
  [[ ${output} =~ 'pip install --upgrade pip setuptools' ]]
}

@test "pipsi install global runs 'install pkg' with appropriate options" {
  run pipsi install missing_package_is_missing --global
  (( status == 0 ))
  run baked_output
  [[ ${lines[${#lines[@]}-2]} =~ ^\ *pipsi ]]
  [[ ${lines[${#lines[@]}-2]} =~ --bin-dir=${pipsi_global_bin_dir} ]]
  [[ ${lines[${#lines[@]}-2]} =~ --home=${pipsi_global_home} ]]
  [[ ${lines[${#lines[@]}-2]} =~ install\ missing_package_is_missing ]]
}

@test "pipsi install global uses sudo if necessary to write to target dirs" {
  respond_to "test -w ${pipsi_global_bin_dir}/" 'return 1'
  respond_to "test -w ${pipsi_global_home}/" 'return 1'

  run pipsi install missing_package_is_missing --global
  (( status == 0 ))
  run baked_output
  [[ ${lines[${#lines[@]}-2]} =~ ^sudo\ pipsi ]]
}

@test "pipsi upgrade runs 'upgrade pkg'" {
  run pipsi upgrade outdated_package
  (( status == 0 ))
  run baked_output
  [[ ${output} =~ 'pipsi upgrade outdated_package' ]]
}

@test "pipsi upgrade global runs 'upgrade pkg' with appropriate options" {
  run pipsi upgrade outdated_package --global
  (( status == 0 ))
  run baked_output
  [[ ${lines[${#lines[@]}-1]} =~ ^\ *pipsi ]]
  [[ ${lines[${#lines[@]}-1]} =~ --bin-dir=${pipsi_global_bin_dir} ]]
  [[ ${lines[${#lines[@]}-1]} =~ --home=${pipsi_global_home} ]]
  [[ ${lines[${#lines[@]}-1]} =~ upgrade\ outdated_package ]]
}

@test "pipsi upgrade global uses sudo if necessary to write to target dirs" {
  respond_to "test -w ${pipsi_global_bin_dir}/" 'return 0'
  respond_to "test -w ${pipsi_global_home}/" 'return 1'

  run pipsi upgrade outdated_package --global
  (( status == 0 ))
  run baked_output
  [[ ${lines[${#lines[@]}-1]} =~ ^sudo\ pipsi ]]
}

@test "pipsi delete runs 'uninstall pkg'" {
  run pipsi delete current_package
  (( status == 0 ))
  run baked_output
  [[ ${output} =~ 'pipsi uninstall current_package' ]]
}

@test "pipsi remove runs 'uninstall pkg'" {
  run pipsi remove current_package
  (( status == 0 ))
  run baked_output
  [[ ${output} =~ 'pipsi uninstall current_package' ]]
}

@test "pipsi delete global runs 'uninstall pkg' with appropriate options" {
  run pipsi delete current_package --global
  (( status == 0 ))
  run baked_output
  [[ ${lines[${#lines[@]}-1]} =~ ^\ *pipsi ]]
  [[ ${lines[${#lines[@]}-1]} =~ --bin-dir=${pipsi_global_bin_dir} ]]
  [[ ${lines[${#lines[@]}-1]} =~ --home=${pipsi_global_home} ]]
  [[ ${lines[${#lines[@]}-1]} =~ uninstall\ current_package ]]
}

@test "pipsi remove global runs 'uninstall pkg' with appropriate options" {
  run pipsi remove current_package --global
  (( status == 0 ))
  run baked_output
  [[ ${lines[${#lines[@]}-1]} =~ ^\ *pipsi ]]
  [[ ${lines[${#lines[@]}-1]} =~ --bin-dir=${pipsi_global_bin_dir} ]]
  [[ ${lines[${#lines[@]}-1]} =~ --home=${pipsi_global_home} ]]
  [[ ${lines[${#lines[@]}-1]} =~ uninstall\ current_package ]]
}

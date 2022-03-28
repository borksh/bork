#!/user/bin/env bats

. test/helpers.sh
user () { . $BORK_SOURCE_DIR/types/user.sh $*; }

linux_users_query="cat /etc/passwd"
darwin_users_query="dscl . -list /Users"
groups_query="groups existant"
setup () {
  respond_to "$linux_users_query" "cat $fixtures/user-list-linux.txt"
  respond_to "$darwin_users_query" "cat $fixtures/user-list-darwin.txt"
  respond_to "$darwin_users_query UniqueID" "cat $fixtures/user-list-darwin-uniqueid.txt"
  respond_to "$groups_query" "echo 'bee existant '"
  respond_to "dscl . -read /Users/existant UserShell" "echo 'UserShell: /bin/bash'"
  respond_to "uname -r" "echo 13"
}

# --- without arguments ----------------------------------------
@test "user status: returns FAILED_PRECONDITION when useradd isn't found (Linux)" {
  respond_to "uname -s" "echo Linux"
  respond_to "which useradd" "return 1"
  run user status foo
  echo "$status"
  [ "$status" -eq $STATUS_FAILED_PRECONDITION ]
}

@test "user status: returns FAILED_PRECONDITION when userdel isn't found (Linux)" {
  respond_to "uname -s" "echo Linux"
  respond_to "which userdel" "return 1"
  run user status foo
  [ "$status" -eq $STATUS_FAILED_PRECONDITION ]
}

@test "user status: returns FAILED_PRECONDITION when dscl isn't found (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  respond_to "which dscl" "return 1"
  run user status foo
  [ "$status" -eq $STATUS_FAILED_PRECONDITION ]
}

@test "user status: returns FAILED_PRECONDITION when sysadminctl isn't found on >14 (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  respond_to "uname -r" "echo 21.3.0"
  respond_to "which sysadminctl" "return 1"
  run user status foo
  [ "$status" -eq $STATUS_FAILED_PRECONDITION ]
}

@test "user status: returns MISSING when user doesn't exist (Linux)" {
  respond_to "uname -s" "echo Linux"
  run user status nonexistant
  [ "$status" -eq $STATUS_MISSING ]
}

@test "user status: returns MISSING when user doesn't exist (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run user status nonexistant
  [ "$status" -eq $STATUS_MISSING ]
}

@test "user status: returns OK when user exists (Linux)" {
  respond_to "uname -s" "echo Linux"
  run user status existant
  [ "$status" -eq $STATUS_OK ]
}

@test "user status: returns OK when user exists (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run user status existant
  [ "$status" -eq $STATUS_OK ]
}

@test "user install: bakes 'useradd' with -m (Linux)" {
  respond_to "uname -s" "echo Linux"
  run user install nonexistant
  [ "$status" -eq 0 ]
  run baked_output
  [ "${#lines[*]}" -eq 2 ]
  [ "${lines[1]}" = "useradd -m nonexistant" ]
}

@test "user install: bakes 'dscl' (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run user install nonexistant
  [ "$status" -eq 0 ]
  run baked_output
  [ "${#lines[*]}" -eq 14 ]
  [ "${lines[2]}" = "sudo dscl . -create /Users/nonexistant" ]
}

@test "user install: bakes 'sysadminctl' if available (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  respond_to "uname -r" "echo 21.3.0"

  run user install nonexistant
  [ "$status" -eq 0 ]
  run baked_output
  [ "${#lines[*]}" -eq 4 ]
  [ "${lines[2]}" = "sudo sysadminctl -addUser nonexistant -password -" ]
}

@test "user install: bakes 'dscl' with real name (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run user install nonexistant --real-name=NewUser
  [ "$status" -eq 0 ]
  run baked_output
  [ "${#lines[*]}" -eq 14 ]
  [ "${lines[8]}" = "sudo dscl . -create /Users/nonexistant RealName NewUser" ]
}

@test "user install: bakes 'useradd' with real name (Linux)" {
  respond_to "uname -s" "echo Linux"
  run user install nonexistant --real-name=NewUser
  [ "$status" -eq 0 ]
  run baked_output
  [ "${#lines[*]}" -eq 2 ]
  [ "${lines[1]}" = "useradd -m -c NewUser nonexistant" ]
}

@test "user remove: bakes 'userdel' with -r (Linux)" {
  respond_to "uname -s" "echo Linux"
  run user remove unwanted
  [ "$status" -eq 0 ]
  run baked_output
  [ "${#lines[*]}" -eq 2 ]
  [ "${lines[1]}" = "userdel -r unwanted" ]
}

@test "user remove: bakes 'dscl' remove command (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  respond_to "dscl . -read /Users/unwanted NFSHomeDirectory" "echo 'NFSHomeDirectory: /Users/unwanted'"
  run user remove unwanted
  [ "$status" -eq 0 ]
  run baked_output
  [ "${#lines[*]}" -eq 4 ]
  [ "${lines[2]}" = "sudo dscl . -delete /Users/unwanted" ]
  [ "${lines[3]}" = "rm -r /Users/unwanted" ]
}

# --- with shell argument -------------------------------------
@test "user status: with shell, returns MISSING when user doesn't exist (Linux)" {
  respond_to "uname -s" "echo Linux"
  run user status nonexistant --shell=/bin/zsh
  [ "$status" -eq $STATUS_MISSING ]
}

@test "user status: with shell, returns MISSING when user doesn't exist (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run user status nonexistant --shell=/bin/zsh
  [ "$status" -eq $STATUS_MISSING ]
}

@test "user status: with shell, returns MISMATCHED_UPGRADE when user exists, wrong shell (Linux)" {
  respond_to "uname -s" "echo Linux"
  run user status existant --shell=/bin/zsh
  [ "$status" -eq $STATUS_MISMATCH_UPGRADE ]
  [ "${#lines[*]}" -eq 1 ]
  echo "${lines[0]}" | grep -E "^--shell:" >/dev/null
  echo "${lines[0]}" | grep -E "/bin/bash$" >/dev/null
}

@test "user status: with shell, returns MISMATCHED_UPGRADE when user exists, wrong shell (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run user status existant --shell=/bin/zsh
  [ "$status" -eq $STATUS_MISMATCH_UPGRADE ]
  [ "${#lines[*]}" -eq 1 ]
  echo "${lines[0]}" | grep -E "^--shell:" >/dev/null
  echo "${lines[0]}" | grep -E "/bin/bash$" >/dev/null
}

@test "user status: with shell, returns OK when user exists, right shell (Linux)" {
  respond_to "uname -s" "echo Linux"
  run user status existant --shell=/bin/bash
  [ "$status" -eq $STATUS_OK ]
}

@test "user status: with shell, returns OK when user exists, right shell (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run user status existant --shell=/bin/bash
  [ "$status" -eq $STATUS_OK ]
}

@test "user install: with shell, bakes 'useradd' with --shell (Linux)" {
  respond_to "uname -s" "echo Linux"
  run user install nonexistant --shell=/bin/zsh
  [ "$status" -eq 0 ]
  run baked_output
  [ "${#lines[*]}" -eq 2 ]
  [ "${lines[1]}" = "useradd -m --shell /bin/zsh nonexistant" ]
}

@test "user install: with shell, bakes 'dscl' with given shell (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run user install nonexistant --shell=/bin/bash
  [ "$status" -eq 0 ]
  run baked_output
  [ "${#lines[*]}" -eq 14 ]
  [ "${lines[13]}" = "sudo dscl . -create /Users/nonexistant UserShell /bin/bash" ]
}

@test "user upgrade: with shell, bakes 'chsh -s' (Linux)" {
  respond_to "uname -s" "echo Linux"
  run user upgrade existant --shell=/bin/zsh
  [ "$status" -eq 0 ]
  run baked_output
  [ "${#lines[*]}" -eq 5 ]
  [ "${lines[1]}" == "$linux_users_query" ]
  [ "${lines[3]}" == "chsh -s /bin/zsh existant" ]
  [ "${lines[4]}" == "$groups_query" ]
}

@test "user upgrade: with shell, bakes 'chsh -s' (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run user upgrade existant --shell=/bin/zsh
  [ "$status" -eq 0 ]
  run baked_output
  [ "${#lines[*]}" -eq 6 ]
  [ "${lines[1]}" == "$darwin_users_query" ]
  [ "${lines[4]}" == "chsh -s /bin/zsh existant" ]
  [ "${lines[5]}" == "$groups_query" ]
}

# --- with group argument ------------------------------------
@test "user status: with group, returns MISSING when user doesn't exist (Linux)" {
  respond_to "uname -s" "echo Linux"
  run user status nonexistant --groups=foo,bar
  [ "$status" -eq $STATUS_MISSING ]
}

@test "user status: with group, returns MISSING when user doesn't exist (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run user status nonexistant --groups=foo,bar
  [ "$status" -eq $STATUS_MISSING ]
}

@test "user status: with group, returns PARTIAL when user belongs to none (Linux)" {
  respond_to "uname -s" "echo Linux"
  run user status existant --groups=foo,bar
  [ "$status" -eq $STATUS_PARTIAL ]
  [ "${#lines[*]}" -eq 1 ]
  echo "${lines[0]}" | grep -E "^--groups:" >/dev/null
  echo "${lines[0]}" | grep -E "foo bar$" >/dev/null
}

@test "user status: with group, returns PARTIAL when user belongs to none (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run user status existant --groups=foo,bar
  [ "$status" -eq $STATUS_PARTIAL ]
  [ "${#lines[*]}" -eq 1 ]
  echo "${lines[0]}" | grep -E "^--groups:" >/dev/null
  echo "${lines[0]}" | grep -E "foo bar$" >/dev/null
}

@test "user status: with group, returns PARTIAL when user belongs to some (Linux)" {
  respond_to "uname -s" "echo Linux"
  run user status existant --groups=foo,bar,bee
  [ "$status" -eq $STATUS_PARTIAL ]
  [ "${#lines[*]}" -eq 1 ]
  echo "${lines[0]}" | grep -E "^--groups:" >/dev/null
  echo "${lines[0]}" | grep -E "foo bar$" > /dev/null
}

@test "user status: with group, returns PARTIAL when user belongs to some (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run user status existant --groups=foo,bar,bee
  [ "$status" -eq $STATUS_PARTIAL ]
  [ "${#lines[*]}" -eq 1 ]
  echo "${lines[0]}" | grep -E "^--groups:" >/dev/null
  echo "${lines[0]}" | grep -E "foo bar$" > /dev/null
}

@test "user status: with group, returns OK when user belongs to all (Linux)" {
  respond_to "uname -s" "echo Linux"
  run user status existant --groups=existant,bee
  [ "$status" -eq $STATUS_OK ]
}

@test "user status: with group, returns OK when user belongs to all (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run user status existant --groups=existant,bee
  [ "$status" -eq $STATUS_OK ]
}

@test "user install: with group, bakes 'useradd' with --groups (Linux)" {
  respond_to "uname -s" "echo Linux"
  run user install nonexistant --groups=foo,bar
  [ "$status" -eq 0 ]
  run baked_output
  [ "${#lines[*]}" -eq 2 ]
  [ "${lines[1]}" = "useradd -m --groups foo,bar nonexistant" ]
}

@test "user install: with group, bakes 'dseditgroup' with groups (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run user install nonexistant --groups=foo,bar
  [ "$status" -eq 0 ]
  run baked_output
  [ "${#lines[*]}" -eq 16 ]
  [ "${lines[14]}" = "sudo dseditgroup -o edit -a nonexistant -t user foo" ]
  [ "${lines[15]}" = "sudo dseditgroup -o edit -a nonexistant -t user bar" ]
}

@test "user install: with group matching user handle, bakes 'useradd' with --groups and -g (Linux)" {
  respond_to "uname -s" "echo Linux"
  run user install nonexistant --groups=nonexistant,foo,bar
  [ "$status" -eq 0 ]
  run baked_output
  [ "${#lines[*]}" -eq 2 ]
  [ "${lines[1]}" = "useradd -m --groups nonexistant,foo,bar -g nonexistant nonexistant" ]
}

@test "user upgrade: with group, bakes 'adduser' with user and group for each group (Linux)" {
  respond_to "uname -s" "echo Linux"
  run user upgrade existant --groups=foo,bar
  [ "$status" -eq 0 ]
  # expect no output or errors
  [[ -z ${output} ]]
  run baked_output
  [ "${#lines[*]}" -eq 5 ]
  [ "${lines[0]}" = "$groups_query" ]
  [ "${lines[3]}" = "adduser existant foo" ]
  [ "${lines[4]}" = "adduser existant bar" ]
}

@test "user upgrade: with group, bakes 'dseditgroup' with user and group for each group (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run user upgrade existant --groups=foo,bar
  [ "$status" -eq 0 ]
  # expect no output or errors
  [[ -z ${output} ]]
  run baked_output
  [ "${#lines[*]}" -eq 5 ]
  [ "${lines[0]}" = "$groups_query" ]
  [ "${lines[3]}" = "sudo dseditgroup -o edit -a existant -t user foo" ]
  [ "${lines[4]}" = "sudo dseditgroup -o edit -a existant -t user bar" ]
}

# --- with preserve-home argument ----------------------------
@test "user remove: bakes 'userdel' without -r (Linux)" {
  respond_to "uname -s" "echo Linux"
  run user remove unwanted --preserve-home
  [ "$status" -eq 0 ]
  run baked_output
  [ "${#lines[*]}" -eq 2 ]
  [ "${lines[1]}" = "userdel unwanted" ]
}

@test "user remove: runs dscl only (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run user remove unwanted --preserve-home
  [ "$status" -eq 0 ]
  run baked_output
  [ "${#lines[*]}" -eq 2 ]
  [ "${lines[1]}" = "sudo dscl . -delete /Users/unwanted" ]
}

# --- inspector ----------------------------------------------

@test "user inspect: lists users (Linux)" {
  respond_to "uname -s" "echo Linux"
  run user inspect
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "ok user nobody" ]
  run baked_output
  [ "${#lines[*]}" -eq 2 ]
  [ "${lines[1]}" == "$linux_users_query" ]
}

@test "user inspect: lists users (Darwin)" {
  respond_to "uname -s" "echo Darwin"
  run user inspect
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "ok user nobody" ]
  run baked_output
  [ "${#lines[*]}" -eq 3 ]
  [ "${lines[2]}" == "$darwin_users_query" ]
}
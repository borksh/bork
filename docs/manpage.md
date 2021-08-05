bork(1) -- The Bash-Operated Reconciling Kludge 
===============================================

## SYNOPSIS

`bork`  
`bork` *`operation`* [*`config-file`*] [*`options`*]

## DESCRIPTION

Bork is a bash DSL for making declarative assertions about the state of a system.

Bork is written against Bash 3.2 and common unix utilities such as sed, awk and
grep. It is designed to work on any UNIX-based system and maintain awareness of
platform differences between BSD and GPL versions of unix utilities.

## ASSERTIONS AND CONFIG FILES

At the heart of bork is making **assertions** in a **declarative** manner via
the `ok` and `no` functions. That is, you tell it *what* you want the system to
look like instead of *how* to make it look like that. An assertion takes a
**type** and a number of arguments. It invokes the type's handler function with
an *action* such as `status`, `install`, or `upgrade`, which determines the
imperative commands needed to test the assertion or bring it up to date. There
are a number of included types in the `types` directory, and bork makes it easy
to create your own. The `no` function works as an opposite to `ok` -- an `ok`
assertion will require the *presence* of something, and a `no` assertion will
require its absence.

When run, bork will test each `ok`/`no` assertion and determine if it's met or
not. If not, bork can go ahead and *satisfy* the assertion by installing,
upgrading, removing, or otherwise altering the configuration of the item to
match the assertion. It will then test the assertion again. Declarations are
idempotent -- if the assertion is already met, bork will not do anything.

When you're happy with your config script, you can compile it to a standalone
script which does not require bork to run. The compiled script can be passed
around via curl, scp or the like and run on completely new systems.

## ASSERTION TYPES

You can run `bork types` from the command line to get a list of the assertion
types and some basic information about their usage and options.

## RUNTIME OPERATIONS

Per the usage guide, bork has a few main modes of operation:

- `status`: Reports on the status of the assertions in a config file.
- `satisfy`: Checks the status of assertions in a config file, satisfying them
  where needed.
- `compile`: Compiles a config file to a standalone script.
- `check`: Performs a status report on a single assertion.
- `do`: Performs a satisfy operation on a single assertion.
- `inspect`: Output a Bork-compatible config file based on the current state of
the system.

### `status` *`config-file`*

The `status` command will confirm that assertions are met or not, and output
their status. It will not take any action to satisfy those assertions. There are
a handful of statuses an assertion can return, and this since this mode is the
closest bork can do to a true 'dry run'\*, you can use it to test a script
against a pre-existing machine.

\* Some types, such as `git`, need to modify local state by talking to the
network (such as performing `git fetch`), without modifying the things the
assertion aims to check.

The status command will give you output such as:

```
outdated: brew
ok: brew git
missing: brew zsh
ok: directory /Users/skylar/code
conflict (upgradable): github skylarmacdonald/dotfiles
local git repository has uncommitted changes
ok: symlink /Users/skylar/.gitignore /Users/skylar/code/dotfiles/configs/gitignore
conflict (clobber required): symlink /Users/skylar/.lein /Users/skylar/code/dotfiles/configs/lein
not a symlink: /Users/skylar/.lein
mismatch (upgradable): defaults com.apple.dock tilesize integer 36
expected type: integer
received type: float
expected value: 36
received value: 55
```

Each item reports its status like so:

- `ok`: The assertion is met as best we can determine.
- `no`: The assertion is met, because the item is absent from the system.
- `missing`: The assertion is not met, and no trace of it ever being met was found.
- `present`: The assertion is not met, as something is present on the system
  that shouldn't be. It can be satisfied by removing the item.
- `outdated`: The assertion is met, but can be upgraded to a newer version.
- `mismatch (upgradable)`: The assertion is not met as specified, something is
  different. It can be satisfied easily. An explanation will be given.
- `conflict (upgradable)`: The assertion is not met as specified. It can be
  satisfied easily, but doing so may result in data loss.
- `conflict (clobber required)`: The assertion is not met as specified. Bork
  cannot currently satisfy this assertion. In the future, it will be able to,
  but doing so may result in data loss.

### `check` *`assertion`*

The `check` command will take a single assertion on the command line and perform
a `status` check as above for it.

### `satisfy` *`config-file`*

The `satisfy` command is where the real magic happens. For every assertion in
the config file, bork will check its status as described in the `status` command
above, and if it is not `ok` or `no` it will attempt to make it `ok` or `no`,
typically via *installing*, *upgrading* or *removing* something -- but sometimes
a *conflict* is detected which could lose data, such as a local git repository
having uncommitted changes. In that case, bork will warn you about the problem
and ask if you want to proceed. Sometimes conflicts are detected which bork does
not know how to resolve — it will warn you about the problem so you can fix it
yourself.

### `do` *`assertion`*

The `do` command will take a single assertion on the command line and perform a
`satisfy` operation on it as above.

### `compile` *`config-file`*

The `compile` command will output to STDOUT a standalone shell script that does
not require bork to run. You may pass this around as with any file via curl or
scp or whatever you like and run it. Any sub-configs via `include` will be
included in the output, and any type that needs to include resources to do what
it does, such as the `file` type, will include their resources in the script as
base64 encoded data.

### `inspect` *`type`*

The `inspect` command will ask a type for a current inventory of how a system is
configured, and output to STDOUT a Bork-compatible config file to configure the
same state. For example, when used with the `brew` type, this will list all
formulae installed with Homebrew and output a config file to check for those
same formulae. **Not all types will work with this command.** Bork will exit
with code 1 if a type has not implemented `inspect`.

## CUSTOM TYPES

Writing new types is pretty straightforward, and there is a guide to writing
them in the `docs/` directory. If you wish to use a type that is not in bork's
`types` directory, you can let bork know about it with the `register`
declaration:

```bash
register etc/pgdb.sh
ok pgdb my_app_db
```

## COMPOSING CONFIG FILES

You may compose config files into greater operations with the `include`
directive with a path to a script relative to the current script's directory.

```bash
# this is main.sh
include databases.sh
include etc/projects.sh
```

```bash
# this is etc/projects.sh
include project-one.sh
include project-two.sh
# these will be read from the etc/ directory
```

### TAKING FURTHER ACTION ON CHANGES

Bork has two types of callback: before and after functions. These are only used
when Bork is satisfying assertions (i.e. when running `bork satisfy`).

Until Bork starts processing an assertion made with `ok` or `no`, there's no way
to know if anything will change. Therefore, Bork will look for and execute
functions with known names while it processes an assertion, before making the
change.

The functions Bork expects are named:

- `bork_will_change`: Bork will make any change at all to the system, i.e., the
  assertion is not satisfied and Bork will change it.
- `bork_will_install`: The assertion is completely missing, and Bork will
  install something fresh to satisfy it.
- `bork_will_upgrade`: The assertion is partially satisfied, but needs upgrading
  (e.g. an outdated package, a file with the wrong permissions). Bork will
  change it in-place to satisfy it fully.
- `bork_will_remove`: The assertion specifies the removal of something that is
  present on the system, and Bork will remove it to satisfy the assertion.

Each of these will be unset by Bork after it has run them. You should only
define these functions immediately before the assertion you wish to apply them
to.

Bork will also call all of these functions with `_any` appended to the names
(e.g. `bork_will_change_any`) -- these callbacks will not be unset, and will be
called every time it applies.

These are used as follows:

```bash
bork_will_install () {
  echo "callback says hello world"
}
ok directory foo
```

Bork will then output the following if (and only if) the directory `foo` has
been newly created:

```
missing: directory foo
callback says hello world
verifying install: directory foo
* success
```

If the directory had already existed, the `bork_will_install` function would not
have been called. Bork would also not have called the function if it had
upgraded the state of the system, e.g. if the directory had existed but had the
incorrect permissions.

After Bork has made a change, you may call a provided function in your script to
determine the outcome of the change. These are used as follows:

```bash
ok brew fish
if did_install; then
  sudo echo "/usr/local/bin/fish" >> /etc/shells
  chsh -s /usr/local/bin/fish
fi
```
There are four functions to help you take further actions after a change:

- `did_install`: did the previous assertion result in the item being installed
  from scratch?
- `did_upgrade`: did the previous assertion result in the existing item being
  upgraded?
- `did_update`: did the previous assertion result in either the item being
  installed or upgraded?
- `did_remove`: did the previous assertion result in the existing item being
  removed (e.g. deleted or uninstalled)?
- `did_error`: did attempting to install or upgrade the previous assertion
  result in an error?

Unlike with before callbacks, Bork will not call any functions after making a
change. It is up to you to handle the logic however you wish. As with the before
callbacks, you are strongly advised to use these functions immediately after the
assertion you wish to check.

## SEE ALSO

Bork documentation: <https://skylarmacdonald.github.io/bork>

## AUTHORS

Bork's lead maintainer is Skylar MacDonald. It was created and previously
maintained by Matthew Lyon.

A full list of contributors is available on GitHub:  
<https://github.com/skylarmacdonald/bork/graphs/contributors>

## BUGS

See our issues on GitHub:  
<https://github.com/skylarmacdonald/bork/issues>

[SYNOPSIS]: #SYNOPSIS "SYNOPSIS"
[DESCRIPTION]: #DESCRIPTION "DESCRIPTION"
[ASSERTIONS AND CONFIG FILES]: #ASSERTIONS-AND-CONFIG-FILES "ASSERTIONS AND CONFIG FILES"
[ASSERTION TYPES]: #ASSERTION-TYPES "ASSERTION TYPES"
[RUNTIME OPERATIONS]: #RUNTIME-OPERATIONS "RUNTIME OPERATIONS"
[CUSTOM TYPES]: #CUSTOM-TYPES "CUSTOM TYPES"
[COMPOSING CONFIG FILES]: #COMPOSING-CONFIG-FILES "COMPOSING CONFIG FILES"
[TAKING FURTHER ACTION ON CHANGES]: #TAKING-FURTHER-ACTION-ON-CHANGES "TAKING FURTHER ACTION ON CHANGES"
[SEE ALSO]: #SEE-ALSO "SEE ALSO"
[AUTHORS]: #AUTHORS "AUTHORS"
[BUGS]: #BUGS "BUGS"

[-]: -.html

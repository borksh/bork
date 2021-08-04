# How to write a Bork assertion type

So, you have something you'd like to be able to track with bork's `ok` declaration. Perhaps it's the presence of packages from yet another programming language's packaging system, perhaps something you interact with through the shell. If you can programmatically determine if it's present, and programmatically make it present, you can probably make a Bork assertion type out of it.

## Action calls

Bork assertions are scripts that are called by the runner. Ideally they could be run independently of the runner, provided the bork helpers are loaded via `bork load`, if they even call on the helpers. The runner calls with an `action` and the arguments provided to `ok`. For example, this call to `ok`:

```
ok brew bats
```

is transformed into one or more of calls to the `brew` assertion:

```
types/brew.sh status bats
types/brew.sh install bats
types/brew.sh upgrade bats
```

Most of the bork "core" assertions use a case statement to switch on the provided "action".

The runner decides what calls to perform based on its current operation and the state of the system. Here are the actions a script can expect from the runner:

### `desc`

```
types/file.sh desc
```

Outputs basic usage information. This is included in `bork types`. Only really useful right now for scripts that are in the `types/` directory included with bork.

### `status`

```
types/file.sh status path/to/targetfile path/from/sourcefile
```

When called with `status`, the assertion script should determine if the assertion is met, and return a code to indicate the current status of the assertion. It _may_ echo messages to STDOUT indicating guidance to the user indicating any problems or warnings.

Example: checks that targetfile exists, has the same md5 sum as sourcefile.

See the [Status codes reference](./assertion_status_codes) for the complete list. Note that in the case of negative assertions with the `no` command, you should still return the status as normal -- the `no` command is expecting you to return `10` to verify things are completely missing from the system.

### `install`

```
types/file.sh install path/to/targetfile path/from/sourcefile
```

When called with `install`, the assertion script should assume that `status` was called with the same arguments and returned `10`; that is, nothing about the assertion exists on the host system.

Example: copies sourcefile to targetfile.

The script should output any relevant messages, and return 0 on success.

### `upgrade`

```
types/file.sh upgrade to/targetfile from/sourcefile --permissions=700
```

When called with `upgrade`, the assertion script should assume that `status` was called with the same arguments and returned 11, 12, or 20. Enough of the assertion exists that a different, hopefully quicker path can be taken to satisfying the assertion.

Example: Updates the permissions on targetfile to 700.

The script should output any relevant messages and updates, and return 0 on success.

### `remove`

```
types/file.sh remove to/targetfile from/sourcefile
```

The script should remove the artifacts of the assertion from the system. The assertion can assume that `status` was called with the same arguments and returned a status indicating it was present (i.e. not `10` for missing) on the system.

Example: Deletes targetfile

The script should output any relevant messages, and return 0 on success.

### `compile`

```
types/file.sh compile to/targetfile from/sourcefile
```

Echo any relevant information about the current system for the given arguments that will be copied to the compiled script. The compiled script itself will be included by the compiler, as will the assertion that is calling 'compile' to begin with.

When called from the compiled script, you can test `is_compiled` in status, install, etc., to determine if you need to do anything differently.

Example: base64-encodes `sourcefile` and assigns it to a variable that maps to its path. The `status` and `install` actions know to use this variable instead of looking for the sourcefile and base64-decode its contents.

## Helpers

Bork makes a number of helpers available to ease common bash scripting pain points. They are in the `lib/helpers` directory, but there is one in particular you should be familiar with when writing assertion type scripts:

### `bake`

Bork has the notion of the "source system" and the "target system". They are currently realized only in the scope of the "compile" operation, but in the future it might be possible to run bork locally and have it execute commands on another host system via ssh. The key to doing this is `bake`.

Any command that queries the state of or modifies the target system should be run through bake. In normal operation, it will simply eval the command as passed. Querying the state of the "source system" or logic do not need to be passed through bake.

This is a little bit of overhead, but I believe it will yield promising results. Controlling remote hosts is one possibility, providing "compile" with an option to just do a super-lightweight install script is another. It's used for mocking behavior in the tests.
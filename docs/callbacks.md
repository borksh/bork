# Callbacks guide

Bork has callbacks that allow you to carry out your own custom actions before or after it makes changes. How to use these is explained briefly in the [readme](/bork) and [man page](manpage), but there's a more detailed explanation below.

## Before callbacks

When you run `bork satisfy`, Bork first checks the status of each assertion, to determine whether it needs to take any actions. Once it has done this, it tells you what it has found, and sets about correcting it if necessary to bring the state of the system in line with the assertions. When Bork is doing these checks, it will call some functions with specific names, so that you can take your own actions before Bork makes any changes.

Bork will only call these functions if it is about to make changes to the system; if an assertion is already satisfied, the before callbacks won't run.

The callbacks available are:

- `bork_will_change`: Bork will make any change at all to the system, i.e., the assertion is not satisfied and Bork is about to change something to attempt to satisfy it.
- `bork_will_install`: The assertion is completely missing, and Bork will install something fresh to satisfy it.
- `bork_will_upgrade`: The assertion is partially satisfied, but needs upgrading (e.g. an outdated package, a file with the wrong permissions). Bork will change it in-place to satisfy it fully.
- `bork_will_remove`: The assertion requires the absence of something that is present on the system, and Bork will remove it to satisfy the assertion.

Bork will call functions with these exact names, if they exist, before taking action. It will then unset them to ensure they're not called twice. Here's an example from the [Readme](/bork):

```bash
bork_will_install () {
  echo "callback says hello world"
}
ok directory foo
ok directory bar
```

Bork will then output the following if (and only if) the directory `foo` has been newly created:

```
missing: directory foo
callback says hello world
verifying install: directory foo
* success
missing: directory bar
verifying install: directory bar
* success
```

As you can see above, the function is unset before satisfying the second assertion, so it isn't run again. You can prevent this by defining functions ending in `_any`, such as `bork_will_install_any`, like so:

```bash
bork_will_install_any () {
  echo "this callback will not be unset"
}
ok directory foo
ok directory bar
```

This function will run every time Bork installs *anything*:

```
missing: directory foo
this callback will not be unset
verifying install: directory foo
* success
missing: directory bar
this callback will not be unset
verifying install: directory bar
* success
```

If the directories already exist, or if Bork were to run any action other than installing, the functions wouldn't run.

### Arguments

The above is a very simplistic example, showing when the callbacks are run. However, Bork will call them with the full set of arguments passed to the assertion, so you can figure out what Bork was doing when it ran your callback. This is more useful for `_any` callbacks, but can be used with either kind. For example:

```bash
bork_will_install_any () {
  if [ "$1" = "directory" ]; then
    echo "Bork is creating a directory"
  else
    echo "Bork is doing something else"
  fi
}
ok directory foo
ok github foo/bork borksh/bork --ssh --branch=main
```

That will output:

```
missing: directory foo 
Bork is creating a directory
verifying install: directory foo
* success
missing: github foo/bork borksh/bork --ssh --branch=main 
Bork is doing something else
Cloning into 'foo/bork'...
[git output goes here]
verifying install: github foo/bork borksh/bork --ssh --branch=main
* success
```

### A word of warning

Remember that these callbacks are always run after an assertion is *tested*, but before an assertion is *run*. There is no guarantee that Bork will not fail to satisfy the assertion owing to circumstances outside its control (e.g. file permissions or network connectivity problems). You should use the 'after functions' if you need the assertion to be true by the time you start acting on it.

## After functions

Unlike the before callbacks, Bork doesn't call any functions after it finishes satisfying an assertion. Instead, there are some functions you can call to check the last thing that Bork did. They are:

- `did_install`: did the previous assertion result in the item being installed from scratch?
- `did_upgrade`: did the previous assertion result in the existing item being upgraded?
- `did_remove`: did the previous assertion result in the existing item being removed (e.g. deleted or uninstalled)?
- `did_update`: did the previous assertion result in either the item being installed, upgraded or removed?
- `did_error`: did attempting to install/upgrade/remove the previous assertion result in an error?

These return code `0` when they're true, allowing you to use them in `if` statements:

```bash
ok brew fish
if did_install; then
  ok shells $(brew --prefix)/bin/fish
  chsh -s $(brew --prefix)/bin/fish
fi
```

Additionally, there is `any_updated`, which will return `0` (i.e. true) if Bork has changed (i.e. installed, upgraded or removed) **anything at all** at **any point** in your script. Use with caution.

## Where to define before/after actions in your scripts

You should define your before callbacks or use after functions **immediately before or after** the assertion they apply to. When Bork is checking an assertion, it unsets all possible before callbacks, and clears the variables used by the after functions. You can't rely on Bork to remember the outcome of one assertion once it's moved onto another one.

However, if you want to keep your scripts tidy, you can always write your own functions, and have Bork call them like this:

```bash
bork_will_install () {
  # it's a good idea to pass on the arguments too
  my_directory_install_function "$*"
}
ok directory foo

# elsewhere in the file...

my_directory_install_function () {
  echo "Bork is creating the foo directory"
}
```

## Why would I want to do this?

In short: I don't know! That's why Bork has this feature -- so that you can build things we haven't thought of. You don't have to use this feature to use Bork, but it allows you some extra flexibility when writing your scripts.
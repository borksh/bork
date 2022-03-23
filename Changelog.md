# Change Log
All notable changes to this project will be documented in this file, from 2016-03-24 going forward. This project adheres to [Semantic Versioning](http://semver.org/).

## Next release

Changes here will be in the next release. You can use them now by checking out the HEAD of the `main` branch, or specifying the `--HEAD` option with `brew install bork`.

### Added
- Bork now supports before hooks. You can define functions named `bork_will_change`, `bork_will_install`, `bork_will_upgrade` or `bork_will_remove`, and Bork will run them just before making any changes. (#16)
- You can now use the `no` command in place of `ok` to check for the absence, rather than the presence, of an assertion. This will delete files, uninstall packages, etc. when satisfying to ensure an assertion is absent from the system. (#9)
  - A new `did_remove` function has been added, which you can use after an assertion to determine whether Bork has removed something.
- Tab completions are now available for bash and zsh. (#19)

## [0.13.0] - 2021-08-02

This was originally pre-released as 0.13.0-rc.1 on 2021-07-29.

The second release under Bork's new maintainership! Thank you in particular to [@lucymhdavies][] for your work on many of the changes below.

### Fixed
- Homebrew is now installed with a shell script instead of the Ruby installer. (#7)
- the `mas` type will now check that the user is signed into the App Store before continuing.
- The `mas` type will now only update the specified apps instead of all installed apps. (#18)
- The `download` type will now follow redirects. (#21)

### Added
- Bork now has a man page in `docs/`. This will be installed by the next version of the Homebrew formula, but can be installed manually as well by linking or copying into `/usr/share/man/man1` (or wherever you keep your man pages).
- `bork types` now supports a single type as an argument to get documentation for that specific type only.
- `bork inspect` will generate a Bork-compatible config file based on the current status of the system. This is currently available on a per-type basis only, and will only be implemented for some types. (#14)
- Bork will now report its version by running `bork --version` (or `bork version`).
- The `git` type can now show untracked files, using the `--untracked-files` option. It responds to the same values as the `--untracked-files` option on git: `no` (default, ignore them), `normal` or `all`. (#28)
- The `brew` type now accepts a `--HEAD` option, which will install the latest available git commit as though you had specified the option on the `brew install` command itself. (#31)
- Bork will now display its output in colour if the `BORK_COLOR` environment variable is set. (#24)

## [0.12.0] - 2021-02-20

Hello! I've forked bork in 2021 to fix some bugs and carry on the project. I'm indebted to [@mattly][] for his work on it up to this point.

### Fixed
- the `cask` type will now work with updated versions of Homebrew, where `brew cask install` has been replaced with `brew install --cask`.
- all tests should now pass on BSD and GPL environments (tested on macOS and Ubuntu, please raise an issue if you run into failures on other platforms).
- CI changed to GitHub Actions and running in a matrix on both macOS and Ubuntu runners.

### Added
- new `pip3` type for Python 3.x
- new `shells` type for registering a shell in `/etc/shells`
- `apk` type support has now been merged and the tests fixed. Thanks [@mattly][] & [@jitakirin][] for your work in 2018!
- there is now Markdown documentation in `docs/`, which is also the source of the [GitHub Pages site](https://borksh.github.io/bork).

## [0.11.1] - 2018-01-28

### Deprecated
- The `--size` option in the `download` type is going away. It will be replaced with some sort of hash checking option.

### Fixed
- the `ok` statement now single-quotes arguments to the type handler. This is the first step in a more consistent and correct behavior for quoting things in Bork. [@martinwalsh]
- The github type once again works correctly in compiled scripts. [@mattly][]
- There is no longer a `bin/bork_compile` script for someone to try to run when they shouldn't. [@mattly][]
- Homebrew doesn't treat tap names as case-sensitive, and now neither does bork. [@mattly][]
- Clarified some documentation around the update behavior for the brew-tap type [@mattly][]

## [0.11.0] - 2018-01-27

Hey folks, sorry it's been a while! I started a new job not long after 0.10.0 was relased and then had my first child not long after that. I'm finally feeling a bit like I have some spare time. -- [@mattly][]

### Added
- new `--owner`, `--group`, and `--mode` flags for the `directory` type that do what you think they do. Thanks [@jitakirin][]
- `zypper` type for working with the SUSE package manager. Thanks [@jitakirin][]
- `pipsi` type for installing python packages to virtualenvs. Thanks [@jitakirin][]
- Reference to `#bork` freenode IRC channel in Readme.
- `go-get` type for asserting the presence of a go package. Thanks [@edrex][]
- Use `apm-beta` over `apm` if it is available. Thanks [@frdmn][]

### Improved
- Let homebrew itself tell us whether it is outdated. Thanks [@frdmn][]

### Fixed
- Use `npm install` to update npm packages, because `npm upgrade` could install things "newer" than the latest, causing an "outdated" status from bork. By [@mattly][]
- Don't check a user's shell if not requested. Thanks [@jitakirin][]
- Fix for removing an item from a bag value. Thanks [@ngkz][]
- Add version flag to `brew cask` check to bypass warning. Thanks [@rmhsilva][]
- Readme typo fix. Thanks [@indigo423][]
- force legacy listing format for PIP for conformative parsing. Thanks [@frdmn][]
- fix apt-status for outdated packages. Thanks [@dylanvaughn][]
- bypass homebrew not to auto-update itself when performing checks. Thanks [@frdmn][]
- the `desired_type` variable on the `defaults` type is now escaped when checking. Thanks [@bcomnes][]
- the `--size` flag check on the `download` type. Thanks [@bcomnes][]
- Some typos in the readme. Thanks [@rgieseke][]

## [0.10.0] - 2016-03-29

### Added

- `bag` helper: added `print` command to echo each item as a line
- `git` type: added an option to explicitly set the destination. These are equivalent:

    ```bash
    cd ~/code; ok git git@somewhere.com:/me/someproject.git
    ok git ~/code/someproject git@somewhere.com:/me/someproject.git
    ```

    I am inclined to deprecate the original implicit version, and welcome feedback about this.

- `github` type: made to work with explicit destination option for `git` above.
- `github` type: added `-ssh` option to specify `git@github.com:` style urls.
- new `apm` type for managing packages for the [Atom](https://atom.io) text editor. Thanks [@frdmn][]
- `npm` type: Tests!
- `npm` type: Added outdated/upgrade support.
- `Readme.md`: Added installation instructions, moved some sections around. Thanks [@frdmn][]
- `Changelog.md`: moved from `History.md`, improved organization.

### Deprecated

- `destination` declaration is now a proxy for unix `cd`, and will emit to STDERR a message stating it will be removed in the future.

### Removed

- `ok` declaration no longer runs commands from the set `destination`; it will run them from the current directory.

### Fixed

- `dict` type: fix handling for `dict` entries.
- `dict` type: alias `int` type to `integer`.
- `symlink` type: properly quote target in status checks.
- `npm` type: Some versions of the `npm` executable have a bug preventing `--depth 0` and `--parseable` from working together. We work around this by using only `--depth 0` and parsing that output manually.
- `file` type: during `compile` operation, if file is missing, will halt the compile and emit an error to STDERR.

## [0.9.1] — 2016-03-25

### Fixed

- Fix a regression introduced in fd49cab that assumed the bork script path (passed on the command line) was relative. Thanks @frdmn

## [0.9] – 2016-03-24

Initial tagged release, prompted by getting bork into homebrew. Conversely, about three years after I started working on this project.

[@bcomnes]: https://github.com/bcomnes
[@dylanvaughn]: https://github.com/dylanvaughn
[@edrex]: https://github.com/edrex
[@frdmn]: https://github.com/frdmn
[@indigo423]: https://github.com/indigo423
[@jitakirin]: https://github.com/jitakirin
[@martinwalsh]: https://github.com/martinwalsh
[@mattly]: https://github.com/mattly
[@ngkz]: https://github.com/ngkz
[@rgieseke]: https://github.com/rgieseke
[@rmhsilva]: https://github.com/rmhsilva
[@lucymhdavies]: https://github.com/lucymhdavies

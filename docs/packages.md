# Packages

For convenience, Bork is available through package managers as well as from source. Generally speaking, the packages will install the contents of the GitHub repository somewhere on your system, but for some it may be a more convenient method of installation and updating than cloning the repository via git.

This page tracks the packages available and their current versions. You can use this to quickly check if the version available to you through your package manager is up to date, in case there is functionality you are expecting that does not seem to work.

Bork will not depend on other packages in your package management ecosystem.

## Quick reference

This quick reference uses [shields.io](https://shields.io) to fetch the latest packages available at a glance. It may not be accessible to screen readers if your screen reader cannot read SVG files. The information is available in plain text later on this page.

![Latest GitHub release](https://img.shields.io/github/v/release/borksh/bork)  
![Latest version available via Homebrew](https://img.shields.io/homebrew/v/bork)  
![Latest version available via npm](https://img.shields.io/npm/v/@borksh/bork)  
![GitHub commits since latest release](https://img.shields.io/github/commits-since/borksh/bork/latest/main)

The last one is how many commits have been made to `main` since the latest release. The bigger the number, the sooner a new release is likely to come.

## Packages available

### Homebrew

Formula: bork  
Version: 0.14.0  
Link to formula: <https://formulae.brew.sh/formula/bork>  
Formula code: <https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/bork.rb>  

### npm

Package: @borksh/bork  
Version: 0.14.0  
Link to registry: <https://www.npmjs.com/package/@borksh/bork>

## Pre-built system packages

Starting with version 0.13.0, packages are available for a handful of operating systems on the [GitHub releases page](https://github.com/borksh/bork/releases). These are generally from CI and built unsigned, but SHA-1 hashes are always
available. Packages are currently available for the following operating systems:

- Debian/Ubuntu-like (`.deb`)
- Fedora/CentOS/Red Hat (`.rpm`)
- macOS installer (`.pkg`)
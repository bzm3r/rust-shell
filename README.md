# A Rust Development Shell

## Purpose
* providing rust-analyzer etc. to IDEs
* running and testing programs on a local machine

A "development shell" does not provide a pure environment entirely disconnected from the programmers's environment; in fact, it is meant to integrate with various *development*-smoothing tools available in the user's environment (e.g. shells, aliases, scripts, IDEs, etc.).

Therefore, the intention is that once development of a program/library is complete and ready for distribution, it should be built and tested in a pure environment (where there might also be less convenience features out-of-the-box meant to smooth development experience), and then packaged using such an environment.

Furthermore, the shell is not meant to be used only by one Rust project, but any projects that can all make do with the same tools. Tools such as `sccache` help to cache rustc build artifacts for sharing between projects.

## Features
Features that are provided by a development shell are:
* rust-analyzer
* rustfmt
* clippy
* sccache to cache dependency build artifacts for re-use between projects
* mold to speed up linking times
* environment variables to help ease opening of workspaces related to the dev shell in VS Code

## Architecture
The ideas behind its architecture are:
* `mkDevShell` is a `mkShell`-like wrapper around `stdenv.mkDerivation`
* unlike `mkShell`, `mkDevShell` has an `installPhase` which:
    * copies out the environment variables recorded in the `buildPhase`
    * the environment variables collated in its `builtPhase`

## TODO
- [ ] replace all bash with Rust `xshell`/`xflags`-based scripts/programs (and once done, add a "Towards a Bash-free Future" badge)
- [ ] provide multiple shells (rust-stable, rust-nightly, etc.)
- [ ] generalize and extract relevant parts for use with other languages (e.g. Haskell)
- [ ] check for what the user's current shell is, and then then initiate a development shell that uses it, rather than hardcoding use of zsh
- [ ] allow suspension/rewaking of a dev shell?
- [ ] add a "No Flakes" badge

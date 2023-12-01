// #!/usr/bin/env bash
// set -euo pipefail

// cleanup() {
// if [ -f configuration ]; then
//     rm ~bzm3r/nixos-conf/nixos/configuration.nix
// fi
// }

// trap cleanup EXIT

// host=$(hostname)
// echo "Executing rebuild..."
// # nix-instantiate --eval has no raw mode yet
// nixpkgsPath=$(nix-instantiate --eval --read-write-mode ~bzm3r/nixos-conf/nixpkgs/path.nix | tr -d \")
// # Get the ./root.nix relative to this script
// configPath=$(realpath -- "$(dirname -- "${BASH_SOURCE[0]}")/root.nix")

// cp --remove-destination ~bzm3r/nixos-conf/nixos/config-template.nix ~bzm3r/nixos-conf/nixos/configuration.nix
// sd -F 'MISSING' $host ~bzm3r/nixos-conf/nixos/configuration.nix
// # nixos-rebuild always reads Nixpkgs from the NIX_PATH,
// # so we need to set it explicitly to our pinned version
// NIX_PATH=nixpkgs=$nixpkgsPath:nixos-config=$configPath
// export NIX_PATH

// exec nixos-rebuild "$@"

// cleanup

use xshell::{cmd, Shell};

fn main() -> anyhow::Result<()> {
    // By convention, an instance of `Shell` is stored in a variable named `sh`
    // Can have multiple instances of `Shell`.

    // A `Shell`'s` environment is independent of the process-wide
    // std::env::current_dir. Each shell has its own current directory that it
    // it keeps track off, and also has various ``
    let sh = Shell::new()?;

    // Various small primitives exist to do things such as
    // https://docs.rs/xshell/latest/xshell/struct.Shell.html

    // cmd is a convenience for creating Cmd structs
    // https://docs.rs/xshell/latest/xshell/struct.Cmd.html#method.args
    let x = "hello world!";
    cmd!(sh, "echo {x}").run()?;
    Ok(())
}

{ pkgs ? (
    import <nixpkgs> { }
  )
}:
let
  sources = import ./npins;
  rust_over_pkgs = pkgs.extend (import sources.rust-overlay);

  # A wrapper around `pkgs.stdenv.mkShell` that is almost a copy of it
  mkDevShell = (import ./mkDevShell.nix) {
    inherit (rust_over_pkgs) lib buildEnv writeTextFile;
    stdenv = rust_over_pkgs.stdenvAdapters.useMoldLinker rust_over_pkgs.clangStdenv;
  };

  # The name of our custom dev shell (also the name of the package, and the
  # binary script which initializes our shell)
  name = "rust-shell";
  cargoHome = "~/.cargo_${name}";
in
# mkDevShell is mostly just an annotated copy of mkShell; however, it also has
  # an installPhase where it copies out
mkDevShell (
  # The information defining our shell environment (which should be executed in
  # a user's shell, but for now I am hardcoding it as zsh (see the
  # customShellHook attribute).

  rec {
    inherit name cargoHome;
    sccacheDir = "~/.sccache_${name}";
    cargoConfigPath = cargoHome + "/config.toml";
    storedCargoConfig = rust_over_pkgs.writeText "config.toml"
      ''
        [build]
        rustc-wrapper = "${rust_over_pkgs.sccache}/bin/sccache"
      '';
    packages = with rust_over_pkgs; [
      (
        rust-bin.stable.latest.default.override
          {
            extensions = [
              "rustfmt"
              "rust-std"
              "rust-src"
              "rust-analyzer"
              "clippy"
              "llvm-tools-preview"
            ];
          }
      )
      sccache
    ];
    # technically, since the attributes of shellEnv are merged into the attributes
    # pass to `mkDevShell`, we could use the environment variables they are
    # supposed to generate within the shell hook. But, for the sake of clarity and
    # robustness, it is better to be direc by hardcoding in the expected values
    # into the shell hook at creation.
    #
    # This function takes as input a path to the recording of the environment
    # variables that the shell's dependencies helped define. This recording will
    # be created by the `mkDevShell` function.
    #
    # The output of this function will be the primary executable output of the program (i.e. what the
    # user will call). It will be copied into the nix store in the installPhase
    # of the mkDerivation wrapped by mkDevShell.

  }
)

# # TODO: convert this into a Rust script ASAP
# set -xeuo pipefail

# source ${recordedEnvVars}
# # Is this done correctly?
# ${inputHooks}

# # make a .cargo directory (if it doesn't already exist)
# echo "Creating CARGO_HOME at ${cargoHome}"

# # TODO: Should do folder creation elegantly/robustly later (check to see
# # if it exists, rather than just blindly creating it).
# mkdir ${cargoHome}
# export CARGO_HOME=${cargoHome}

# # overwrite any existing config.toml with one from home.
# # TODO: in the future, perform a merge with an existing file?
# cp --remove-destination ${storedCargoConfig} ${cargoConfigPath}

# # create .<name>_sccache cargoConfigDir (if it doesn't already exist)
# echo "Creating SCCACHE_DIR at ${sccacheDir}"
# mkdir ${sccacheDir}
# SCCACHE_DIR=$(realpath ${sccacheDir})
# export SCCACHE_DIR=$SCCACHE_DIR
# # name of the workspace for purposes such as
# export DEFAULT_WORKSPACE=${name}

# # continue in interactive mode

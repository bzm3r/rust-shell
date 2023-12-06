let
  sources = import ./npins;
  pkgs = import sources.nixpkgs {
    overlays = [
      (import sources.rust-overlay)
    ];
  };

  # A wrapper around `pkgs.stdenv.mkShell` that is almost a copy of it
  mkDevShell = (import ./mkDevShell.nix) {
    inherit (pkgs) lib buildEnv writeTextFile;
    stdenv = pkgs.stdenvAdapters.useMoldLinker pkgs.clangStdenv;
  };

  # The name of our custom dev shell (also the name of the package, and the
  # binary script which initializes our shell)
  name = "rust-stable";
  cargoHome = "~/.cargo_${name}";

  # The information defining our shell environment (which should be executed in
  # a user's shell, but for now I am hardcoding it as zsh (see the
  # customShellHook attribute).
  rustShellEnv = rec {
    inherit name cargoHome;
    nixpkgsOutPath = sources.nixpkgs.outPath;
    sccacheDir = "~/.sccache_${name}";
    cargoConfigPath = cargoHome + "/config.toml";
    storedCargoConfig = pkgs.writeText "config.toml"
          ''
            [build]
            rustc-wrapper = "${pkgs.sccache}/bin/sccache"
          '';
    packages = with pkgs; [
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
    customShellHook = recordedEnvVars: pkgs.writeTextFile {
      inherit name;
      text = ''
        #!/usr/bin/env zsh
        set -xeuo pipefail

        source ${recordedEnvVars}

        # export variables
        export nixpkgs=${nixpkgsOutPath}
        export NIX_PATH=nixpkgs=${nixpkgsOutPath}

        # make a .cargo directory (if it doesn't already exist)
        echo "Creating CARGO_HOME at ${cargoHome}"
        mkdir ${cargoHome}
        export CARGO_HOME=${cargoHome}
        # overwrite any existing config.toml
        cp --remove-destination ${storedCargoConfig} ${cargoConfigPath}

        # create .<name>_sccache cargoConfigDir (if it doesn't already exist)
        echo "Creating SCCACHE_DIR at ${sccacheDir}"
        mkdir ${sccacheDir}
        SCCACHE_DIR=$(realpath ${sccacheDir})
        export SCCACHE_DIR=$SCCACHE_DIR
        # name of the workspace for purposes such as
        export DEFAULT_WORKSPACE=${name}

        # continue in interactive mode
        zsh -i
      '';
      executable = true;
    };
  };
in
# mkDevShell is mostly just an annotated copy of mkShell; however, it also has
# an installPhase where it copies out
mkDevShell rustShellEnv


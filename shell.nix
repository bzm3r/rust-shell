let
  sources = import ./npins;
  pkgs = import sources.nixpkgs {
    overlays = [
      (import sources.rust-overlay)
    ];
  };
  name = "rust-stable";
  cacheDir = "~/.${name}_sccache";
  cargoConfigDir = "~/.cargo_${name}/";
  cargoConfigPath = cargoConfigDir + "/config.toml";
in
pkgs.mkShell.override
{
  stdenv = pkgs.stdenvAdapters.useMoldLinker pkgs.clangStdenv;
}
{
  inherit name;

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

  shell = "/usr/bin/zsh";

  shellHook =
    let
      storedCargoConfig = pkgs.writeText "config.toml"
        ''
          [build]
          rustc-wrapper = "${pkgs.sccache}/bin/sccache"
        '';
      nixpkgsOutPath = sources.nixpkgs.outPath;
    in
    ''
      # export variables
      export nixpkgs=${nixpkgsOutPath}
      export NIX_PATH=nixpkgs=${nixpkgsOutPath}

      # make a .cargo directory (if it doesn't already exist)
      echo "Creating CARGO_HOME at ${cargoConfigDir}"
      mkdir ${cargoConfigDir}
      export CARGO_HOME=${cargoConfigDir}
      # overwrite any existing config.toml
      cp --remove-destination ${storedCargoConfig} ${cargoConfigPath}

      # create .<name>_sccache cargoConfigDir (if it doesn't already exist)
      echo "Creating SCCACHE_DIR at ${cacheDir}"
      mkdir ${cacheDir}
      SCCACHE_DIR=$(realpath ${cacheDir})
      export SCCACHE_DIR=$SCCACHE_DIR
      export DEFAULT_WORKSPACE=${name}
    '';
}

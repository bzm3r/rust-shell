let
  sources = import ./npins;
  pkgs = import sources.nixpkgs {
    overlays = [
      (import sources.rust-overlay)
    ];
  };
  name = "rust_stable";
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

  shellHook =
    let
      cargoConfigToml = pkgs.writeText "config.toml"
        ''
          [build]
          rustc-wrapper = "${pkgs.sccache}/bin/sccache"
        '';
    in
    ''
      # export variables
      export nixpkgs=${sources.nixpkgs.outPath}
      export NIX_PATH=nixpkgs=${sources.nixpkgs.outPath}

      # make a .cargo directory (if it doesn't already exist)
      # overwrite any ~/$USER/.<name>_cargo/config.toml that
      # exists
      echo "Creating CARGO_HOME at ${cargoConfigDir}"
      export CARGO_HOME=${cargoConfigDir}
      mkdir ${cargoConfigDir}
      cp --remove-destination ${cargoConfigToml} ${cargoConfigPath}

      # create .<name>_sccache dir (if it doesn't already exist)
      echo "Creating SCCACHE_DIR at ${cacheDir}"
      mkdir ${cacheDir}
      export SCCACHE_DIR="$(realpath ${cacheDir})"

      # initialize zsh (nix-shell starts bash)
      # exec zsh
    '';
}

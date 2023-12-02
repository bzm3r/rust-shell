let
  sources = import ./npins;
  pkgs = import sources.nixpkgs {
    overlays = [
      (import sources.rust-overlay)
    ];
  };
in
pkgs.mkShell.override
{
  stdenv = pkgs.stdenvAdapters.useMoldLinker pkgs.clangStdenv;
}
{
  name = "rust_stable";

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
    npins
  ];

  shellHook =
    let
      cargoConf = pkgs.writeText "cargo.toml"
        ''
          [build]
          rustc-wrapper = "${pkgs.sccache}/bin/sccache"
        '';
    in
    ''
      # export variables
      export nixpkgs=${sources.nixpkgs.outPath}
      export NIX_PATH=nixpkgs=${sources.nixpkgs.outPath}

      # make a cargo directory (if it doesn't already exist)
      mkdir .cargo

      # overwrite any ./.cargo/config.toml that exists
      cp --remove-destination ${cargoConf} ./.cargo/config.toml

      # create .sccache dir (if it doesn't already exist)
      mkdir .sccache

      # let sccache know where we want to store data
      export SCCACHE_DIR="$(realpath ./.sccache)"

      # # use zsh, not bash (nix-shell starts bash)
      # exec zsh
    '';
}

let
  sources = import ./npins;
  pkgs = import sources.nixpkgs {
    overlays = [
      (import sources.rust-overlay)
    ];
  };
in
pkgs.mkShell.override {
  stdenv = pkgs.stdenvAdapters.useMoldLinker pkgs.clangStdenv;
}
{
  buildInputs = with pkgs; [
    npins
  ];

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

  shellHook = let
      cargoToml = pkgs.writeText "cargo.toml"
      ''
        [build]
        rustc-wrapper = "${pkgs.sccache}"
      '';
  in ''
    pwd
    export nixpkgs=${sources.nixpkgs.outPath}
    export NIX_PATH=nixpkgs=${sources.nixpkgs.outPath}
    mkdir -p .cargo
    cp -f ${cargoToml} ./.cargo/cargo.toml
    mkdir ./.cache
    export SCCACHE_DIR=./.cache
  '';
}

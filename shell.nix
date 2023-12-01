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
  name = "rust-template";

  # is this actually necessary here?
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
    mkdir .cargo
    cp --remove-destination ${cargoToml} ./.cargo/Cargo.toml
    mkdir .sccache
    export SCCACHE_DIR="$(realpath ./.sccache)"
    export RUSTC_WRAPPER="$(realpath ./.sccache)"
  '';
}

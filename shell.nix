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
  cargoConfigToml = cargoConfigDir + "/config.toml";
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
    (callPackage )
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
    '';
}

let
  sources = import ./npins;
  pkgs = import sources.nixpkgs {
    overlays = [
      (import sources.rust-overlay)
    ];
  };
  mkDevShell = pkgs.mkShell.override {
    inherit (pkgs) lib buildEnv;
    stdenv = pkgs.stdenvAdapters.useMoldLinker pkgs.clangStdenv;
  };
  name = "rust-stable";
  cacheDir = "~/.${name}_sccache";
  cargoConfigDir = "~/.cargo_${name}/";
  cargoConfigPath = cargoConfigDir + "/config.toml";
in
mkDevShell
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
      nixkpgsOutPath = sources.nixpkgs.outPath;
      hook = (import ./hook.nix) pkgs name nixkpgsOutPath {
        inherit storedCargoConfig;
      };
    in
    ''
      echo $out
      ${hook}
    '';
}


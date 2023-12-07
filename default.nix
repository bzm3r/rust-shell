# pkgs could from the derivation, or outside of it
{ userName
, nixpkgsOutPath ? <nixpkgs>
}:
let
  pkgs = import nixpkgsOutPath {
    overlays = import ./nixpkgs/overlays.nix;
    config = import ./nixpkgs/config.nix;
  };

  # A wrapper around `pkgs.stdenv.mkShell` that is almost a copy of it
  mkDevShell = (import ./mkDevShell.nix) {
    inherit (pkgs) lib buildEnv writeTextFile;
    stdenv = (pkgs.stdenvAdapters.useMoldLinker pkgs.clangStdenv).override {
      cc = null;
      preHook = "";
      allowedRequisites = null;
      initialPath = [ pkgs.coreutils ];
      shell = pkgs.lib.getExe pkgs.bash;
      extraNativeBuildInputs = with pkgs; [
        rustfmt
        rustc
        cargo
        rust-analyzer
        clippy
        sccache
        sd
      ];
    };
  };
  # The name of our custom dev shell (also the name of the package, and the
  # binary script which initializes our shell)
  name = "rust-shell";
  HOME = "/home/${userName}";
in
# mkDevShell is mostly just an annotated copy of mkShell; however, it also has
  # an installPhase where it copies out
mkDevShell (
  # The information defining our shell environment (which should be executed in
  # a user's shell, but for now I am hardcoding it as zsh (see the
  # customShellHook attribute).
  {
    inherit name HOME;
    CARGO_HOME = "${HOME}/.cargo_${name}";
    SCCACHE_DIR = "${HOME}/.sccache_${name}";
    storedCargoConfig = pkgs.writeText "config.toml"
      ''
        [build]
        rustc-wrapper = "${pkgs.sccache}/bin/sccache"
      '';
  }
)

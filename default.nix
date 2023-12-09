# pkgs could from the derivation, or outside of it
{ userName
, name
, pkgs ? (import <nixpkgs> {})
}:
let
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
        # when using VS code + rust-analyzer, make sure to have the extension
        # point to this "ambient" rust-analyzer binary, rather than the one
        # packaged by the extension itself
        rust-analyzer
        clippy
        sccache
        gcc
        mold
        sd
        # vvv Don't care for the trouble below, caused by enabling all build
        # phases. Would much rather just override it to what we know is
        # required. (Otherwise, our scripts our patched unnecessarily, etc.)
        # findutils
        # # ^^^ needed by something during the build process? vvv
        # # /nix/store/ns56yviba3ip2n64g8x9yd74ck525cl4-stdenv-linux/setup: line 1229: find: command not found
        # # error: builder for '/nix/store/kj2ldglqdhh1ml54sf9jildffnb756aw-rust-shell.drv' failed with exit code 127;
        # #        last 3 log lines:
        # #        > patching sources
        # #        > configuring
        # # > /nix/store/ns56yviba3ip2n64g8x9yd74ck525cl4-stdenv-linux/setup: line
        # # 1229: find: command not found
        # gnused
      ];
    };
  };
  # The name of our custom dev shell (also the name of the package, and the
  # binary script which initializes our shell)
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
    IN_NIX_SHELL = "impure"; # these custom shells are impure by construction
  }
)

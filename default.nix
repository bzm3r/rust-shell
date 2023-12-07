{
  pkgs ? (import <nixpkgs> {}),
  userName,
}:
let
  sources = import ./npins;
  rust_over_pkgs = pkgs.extend (import sources.rust-overlay);

  # A wrapper around `pkgs.stdenv.mkShell` that is almost a copy of it
  mkDevShell = (import ./mkDevShell.nix) {
    inherit (rust_over_pkgs) lib buildEnv writeTextFile;
    stdenv = rust_over_pkgs.stdenvAdapters.useMoldLinker rust_over_pkgs.clangStdenv;
  };
  # The name of our custom dev shell (also the name of the package, and the
  # binary script which initializes our shell)
  name = "rust-shell";
  defaultShell = "${rust_over_pkgs.zsh}/bin/zsh";
in
# mkDevShell is mostly just an annotated copy of mkShell; however, it also has
  # an installPhase where it copies out
mkDevShell (
  # The information defining our shell environment (which should be executed in
  # a user's shell, but for now I am hardcoding it as zsh (see the
  # customShellHook attribute).
  {
    inherit name;
    CARGO_HOME = "/home/${userName}/.cargo_${name}";
    SCCACHE_DIR = "/home/${userName}/.sccache_${name}";
    # CONFIG_SHELL=defaultShell;
    # builder=defaultShell;
    # SHELL=defaultShell;
    # shell=defaultShell;
    HOME="home/${userName}";
    storedCargoConfig = rust_over_pkgs.writeText "config.toml"
      ''
        [build]
        rustc-wrapper = "${rust_over_pkgs.sccache}/bin/sccache"
      '';
    packages = with rust_over_pkgs; [
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
  }
)

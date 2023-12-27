let shellFamily = "rust";
in { pkgs ? (import <nixpkgs> { }), lib, description, base ? "~/CACHE", ... }:
assert lib.assertMsg (description != "rust"
  "Description cannot be same as shell family name (${shellFamily})!");
let
  mkDevShell = (import ./npins).mkDevShell;
  stdenv = (pkgs.stdenvAdapters.useMoldLinker pkgs.clangStdenv);
  mkdirs = {
    SHELL_BASE = "${base}/rust/${description}";
    CARGO_HOME = "${base}/rust/${description}";
    SCCACHE_DIR = "${base}/sccache/${description}";
  };
  mkfiles = [{
    text = ''
      [build]
      rustc-wrapper = "${pkgs.sccache}/bin/sccache"
    '';
    path = "${mkdirs.CARGO_HOME}/config.toml";
  }];
  packages = with pkgs; [
    rustfmt
    rustc
    cargo
    rust-analyzer
    clippy
    sccache
    gcc
    mold
  ];

  meta = {
    description =
      "Rust development shell for integration with IDEs and personal experimentation. This is not meant to be an environment within which builds meant for distribution are produced.";
    platforms = pkgs.lib.platforms.all;
    maintainers = [ ];
    mainProgram = description;
  };
in mkDevShell {
  shellName = {
    family = shellFamily;
    inherit description;
  };

  inherit pkgs lib stdenv mkdirs mkfiles packages meta;
}

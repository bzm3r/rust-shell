# pkgs could from the derivation, or outside of it
{ description, base ? "~/CACHE", pkgs ? (import <nixpkgs> { }), lib, ... }:
assert (let shellFamily = "rust";
in lib.assertMsg (description != "rust")
"Description cannot be same as shell family name (${shellFamily})!");
let
  mkDevShell = pkgs.callPackage ((import ./npins).mkDevShell);
  stdenv = (pkgs.stdenvAdapters.useMoldLinker pkgs.clangStdenv);
  mkdirs = rec {
    SHELL_BASE = "${base}/rust/${description}";
    CARGO_HOME = "${base}/rust/${description}";
    SCCACHE_DIR = "${base}/sccache/${description}";
  };
  mkfiles = rec {
    configToml = {
      text = ''
        [build]
        rustc-wrapper = "${pkgs.sccache}/bin/sccache"
      '';
      path = "${mkdirs.CARGO_HOME}/config.toml";
    };
  };
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
    #homepage = "xyz";
    description =
      "Rust development shell for integration with IDEs and personal experimentation. This is not meant to be an environment within which builds meant for distribution are produced.";
    #license = licenses.ofl;
    platforms = pkgs.lib.platforms.all;
    maintainers = [ ];
    mainProgram = description;
  };
in mkDevShell { } { inherit description stdenv mkdirs mkfiles packages meta; }

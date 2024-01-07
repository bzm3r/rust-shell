# pkgs could from the derivation, or outside of it
{ name, cargoHomeBase, pkgs ? (import <nixpkgs> { }), ... }:
let
  sources = import ./npins;
  traceVal = pkgs.lib.traceVal;
  # A wrapper around `pkgs.stdenv.mkShell` that is almost a copy of it
  mkDevShell = pkgs.callPackage sources.mkDevShell {
    stdenv = (pkgs.stdenvAdapters.useMoldLinker pkgs.clangStdenv);
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
      pkg-config
      openssl.dev
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
  # mkDevShell is mostly just an annotated copy of mkShell; however, it also has
  # an installPhase where it copies out
  CARGO_HOME = "${traceVal cargoHomeBase}/.cargo_${name}";
  SCCACHE_DIR = "${traceVal cargoHomeBase}/.sccache_${name}";
  storedCargoConfig = pkgs.writeText "config.toml" ''
    [build]
    rustc-wrapper = "${pkgs.sccache}/bin/sccache"
  '';
  CARGO_CONFIG_PATH = CARGO_HOME + "/config.toml";
  shellInitialization = ''
    mkdir -p "${CARGO_HOME}"
    # TODO: in the future, perform a merge with an existing file?
    cp --remove-destination  ${storedCargoConfig} ${CARGO_CONFIG_PATH}
    mkdir -p "${SCCACHE_DIR}"
  '';
  shellCleanUp = ''
    rm -rf ${CARGO_HOME}
    rm -rf ${SCCACHE_DIR}
  '';
in mkDevShell (
  # The information defining our shell environment (which should be executed in
  # a user's shell, but for now I am hardcoding it as zsh (see the
  # customShellHook attribute).
  {
    inherit name shellInitialization shellCleanUp;

    # these variables will be turned into environment variables.
    inherit CARGO_HOME SCCACHE_DIR;

    meta = {
      #homepage = "xyz";
      description =
        "Rust development shell for integration with IDEs and personal experimentation. This is not meant to be an environment within which builds meant for distribution are produced.";
      #license = licenses.ofl;
      platforms = pkgs.lib.platforms.all;
      maintainers = [ ];
      mainProgram = name;
    };
  })

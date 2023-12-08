{ lib, buildEnv, stdenv, writeTextFile }:
# mkDevShell is closely based on the structure of mkShell
# * https://stackoverflow.com/a/71112117/3486684
{
  # ===========================================
  # mkShell Attributes:
  # https://nixos.org/manual/nixpkgs/unstable/#sec-pkgs-mkShell-attributes
  # ===========================================
  #
  # List of executable packages to add to the nix-shell environment.
  packages ? [ ]
  #
  # -----------------------
  #
  # Add build dependencies of the listed derivations to the nix-shell environment.
, inputsFrom ? [ ]
  #
  # -----------------------
  # Bash statements that are executed by nix-shell.
  #, shellHook ? ""
  # -----------------------
  # ===========================================
  # The following are attributes inherited by mkShell from mkDerivation
  # ===========================================
  #
  # Set the name of the derivation. (Not optional)
, name
  # -----------------------
  # Many packages have dependencies that are not provided in the standard
  # environment. It’s usually sufficient to specify those dependencies in the
  # buildInputs attribute.
  #
  # This attribute ensures that the bin subare listed here:https://nixos.org/manual/nix/unstable/language/derivations.html#derivations
  # * [3] https://nixos.org/guides/nix-pills/fundamentals-of-stdenv#id1463
  #
  # A derivation has a "builder": a script which executes building the
  # derviation. This builder invokes a variety of "phases".
  #
  # Phases can be overridden by setting the envVar/attribute namePhase to a
  # string containing some shell commands to be executed (from within a
  # derivation; note: derivations work so that any attributes that
  # are not "used anywhere" else are turned into environment variables (see ref
  # [2]) or by redefining the shell function namePhase (from within a shell script).
  #
  # Usually: only want to add some commands to a phase, and keep most of it
  # intact. This is usually done by setting pre/post phases. The defaults for
  # each phase can be seen here
  # https://github.com/NixOS/nixpkgs/blob/ec6a7ec59fd4064c7b9535b9c2fe3c441197e3f7/pkgs/stdenv/generic/setup.sh
  #
  # (It seems to me, so far, that we should not add the phase attributes, unless
  # we have a clear/explicit value for them, because otherwise we will end up
  # overriding the phases?)
  #
  # The unpack phase is responsible for unpacking the source code of the
  # package. The buildPhase helps execute commands necessary to "build it"
  # (whatever that means outside of C-ish contexts), and the installPhase copies
  # the output files to their final locations
  #, unpackPhase, buildPhase, installPhase
  #
  # and though we could use the phases, we could also just define our own builder:
  # , builder ? ""
  # #
  # # Add dependencies to nativeBuildInputs if they are executed during the build
  # # process.
  # , nativeBuildInputs ? [ ]
  # # Add dependencies to buildInputs if they will end up copied or linked into the
  # # final output or otherwise used at runtime.
  # , buildInputs ? [ ]
  # # Dependencies needed only to run tests are similarly classified between native
  # # (executed during build) and non-native (executed at runtime). These
  # # dependencies are only injected when doCheck is set to true.
  # #, nativeCheckInputs, checkInputs
  # , propagatedBuildInputs ? [ ]
  # , propagatedNativeBuildInputs ? [ ]
  # The remaining attributes will all be converted to into environment variables
, CARGO_HOME
, SCCACHE_DIR
, storedCargoConfig
, ...
}@inputAttrs:
let
  # deduplicates builtInputs across: 1) any corresponding buildInputs in
  # inputAttrs (the inputs to this `mkDevShell` function), 2) all the
  # derivations listed in `inputsFrom`, and 3) all the corresponding buildInputs
  # of these derivations.
  mergeBuildInputs = buildInputs:
    # check if there is an attribute with the same name as `focusSet` in this
    # `mkDevShell's` input attributes; if so, get it, otherwise begin with the
    # empty list
    (inputAttrs.${buildInputs} or [ ]) ++
    (
      # lib.subtractLists: subtracts first list from second
      # https://nixos.org/manual/nixpkgs/unstable/
      lib.subtractLists
        # first list is a list derivations whose build inputs will be included
        # in the final dev shell's environment.
        inputsFrom
        (
          # flattens nested lists into an un-nested one
          lib.flatten
            # remove all buildInputs that are already listed in inputsFrom
            (lib.catAttrs buildInputs inputsFrom)
        )
    );

  # remove from `attrs` the listed attributes
  rest = builtins.removeAttrs inputAttrs [
    "name"
    "packages"
    "inputsFrom"
    "buildInputs"
    "nativeBuildInputs"
    "propagatedBuildInputs"
    "propagatedNativeBuildInputs"
    "storedCargoConfig"
    "shellHook"
  ];
  CARGO_CONFIG_PATH = CARGO_HOME + "/config.toml";
in
# (From:
  #   * https://nixos.org/manual/nixpkgs/unstable/#sec-using-stdenv
  #   * https://nixos.org/manual/nixpkgs/unstable/#ssec-stdenv-attributes
  # )
stdenv.mkDerivation ({
  inherit name;
  # =================================================================
  # (From: https://nixos.org/manual/nixpkgs/unstable/#chap-cross)
  # Two important categories:
  #   * The “build platform” is the platform on which a package is built. Once
  #     someone has a built package, or pre-built binary package, the build
  #     platform should not matter and can be ignored.
  #   * The “host platform” is the platform on which a package will be run. This
  #     is the simplest platform to understand, b﻿et platform (i.e. isn’t a
  # compiler or similar tool), put it here, rather than in depsBuildBuild.
  #
  # These are programs and libraries used at build time that produce programs
  # and libraries also used at build time. If the dependency doesn’t care about
  # the target platform (i.e. isn’t a compiler or similar tool), put it in
  # nativeBuildInputs instead.
  buildInputs = mergeBuildInputs "buildInputs";

  # =================================================================
  # These are programs and libraries used at build time that produce programs
  # and libraries also used at build time.
  # A list of dependencies whose host platform is the new derivation’s build
  # platform, and target platform is the new derivation’s host platform.
  nativeBuildInputs = packages ++ (mergeBuildInputs "nativeBuildInputs");

  # A list of dependencies whose host platform is the new derivation’s build
  # platform, and target platform is the new derivation’s host platform.
  propagatedBuildInputs = mergeBuildInputs "propagatedBuildInputs";
  propagatedNativeBuildInputs = mergeBuildInputs "propagatedNativeBuildInputs";

  phases = [ "buildPhase" "installPhase" ];

  buildPhase =
    let
      # a concatenation of the various shell hookzs that are required by
      # the buildInputs that go into making up the shell environment
      shellHooks = lib.concatStringsSep "\n" (
        lib.catAttrs "shellHook"
          (
            lib.reverseList inputsFrom ++ [ inputAttrs ]
          )
      );
      mkDirs = ''
        mkdir -p "${CARGO_HOME}"
        # TODO: in the future, perform a merge with an existing file?
        cp --remove-destination  ${storedCargoConfig} ${CARGO_CONFIG_PATH}
        mkdir -p "${SCCACHE_DIR}"
      '';
      shellInitContent = ''
        # shell hooks concatenated from build inputs for this shell
        ${shellHooks}
        # make cargo home directory, sccache directory, and config.toml
        ${mkDirs}
      '';
      shellInit = "shell-init";
      exportFixes = import ./exportFixes.nix { inherit lib shellInit; };
    in
    ''
      # echo "buildPhase PWD: $PWD"
      # echo "buildPhase out: $out"
      # echo "buildPhase ls: $(ls)"

      echo "exporting vars to shellInit"
      export >> ${shellInit}
      ${exportFixes}

      echo "${shellInitContent}" >> ${shellInit}
    '';

  installPhase =
    ''
      runHook preInstall
      # echo "PWD: $PWD"
      # echo "out: $out"
      # echo "ls: $(ls)"
      install -m 755 -D --target-directory $out $PWD/shell-init
      runHook postInstall
    '';

  preferLocalBuild = true;

  meta = with lib; {
    #homepage = "xyz";
    description = "Rust development shell for integration with IDEs and personal experimentation. This is not meant to be an environment within which builds meant for distribution are produced.";
    #license = licenses.ofl;
    platforms = platforms.all;
    maintainers = [ ];
    mainProgram = name;
  };
} // rest)

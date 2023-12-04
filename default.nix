{ lib, stdenv, buildEnv }:

{ name ? "rust-stable"
, # a list of packages to add to the shell environment
  packages ? [ ]
, # propagate all the inputs from the given derivations: list of attrsets
  inputsFrom ? [ ]
, buildInputs ? [ ]
, nativeBuildInputs ? [ ]
, propagatedBuildInputs ? [ ]
, propagatedNativeBuildInputs ? [ ]
, ...
}@attrs:
let
  # essentially a de-duplicating merge
  mergeInputs = name:
    (attrs.${name} or [ ]) ++
    (
      lib.subtractLists # subtracts first list from second
        inputsFrom # first list
        (
          lib.flatten # flattens nested lists into an un-nested one
            # collect each attribute called `name` from a list of attr sets
            (lib.catAttrs name inputsFrom)
        )
    );

  # remove from `attrs` the listed attributes
  rest = builtins.removeAttrs attrs [
    "name"
    "packages"
    "inputsFrom"
    "buildInputs"
    "nativeBuildInputs"
    "propagatedBuildInputs"
    "propagatedNativeBuildInputs"
    "shellHook"
  ];
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
  #     is the simplest platform to understand, but also the one with the worst
  #     name.
  # =================================================================
  # =================================================================
  # (From: https://nixos.org/manual/nixpkgs/unstable/#ssec-distribution-phase)
  # If the dependency doesn’t care about the target platform (i.e. isn’t a
  # compiler or similar tool), put it here, rather than in depsBuildBuild.
  #
  # These are programs and libraries used at build time that produce programs
  # and libraries also used at build time. If the dependency doesn’t care about
  # the target platform (i.e. isn’t a compiler or similar tool), put it in
  # nativeBuildInputs instead.
  buildInputs = mergeInputs "buildInputs";

  # =================================================================
  # These are programs and libraries used at build time that produce programs
  # and libraries also used at build time.
  # A list of dependencies whose host platform is the new derivation’s build
  # platform, and target platform is the new derivation’s host platform.
  nativeBuildInputs = packages ++ (mergeInputs "nativeBuildInputs");

  # A list of dependencies whose host platform is the new derivation’s build
  # platform, and target platform is the new derivation’s host platform.
  propagatedBuildInputs = mergeInputs "propagatedBuildInputs";
  propagatedNativeBuildInputs = mergeInputs "propagatedNativeBuildInputs";

  shellHook = lib.concatStringsSep "\n"  (lib.catAttrs "shellHook"
    (lib.reverseList inputsFrom ++ [ attrs ]));

  phases = [ "buildPhase" ];

  buildPhase = ''
    { echo "------------------------------------------------------------";
      echo " WARNING: the existence of this path is not guaranteed.";
      echo " It is an internal implementation detail for pkgs.mkShell.";
      echo "------------------------------------------------------------";
      echo;
      # Record all build inputs as runtime dependencies
      export;
    } >> "$out"
  '';

  preferLocalBuild = true;
} // rest)

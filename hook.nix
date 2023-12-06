pkgs: name: nixpkgsOutPath: { cargoConfigDir ? "~/.cargo_${name}"
                            , storedCargoConfig
                            , cacheDir ? "~/.sccache_${name}"
                            , ...
                            }:
let
  cargoConfigPath = cargoConfigDir + "config.toml";
in
  pkgs.writeShellApplication {
    inherit name;
    text = ''
      # export variables
      export nixpkgs=${nixpkgsOutPath}
      export NIX_PATH=nixpkgs=${nixpkgsOutPath}

      # make a .cargo directory (if it doesn't already exist)
      echo "Creating CARGO_HOME at ${cargoConfigDir}"
      mkdir ${cargoConfigDir}
      export CARGO_HOME=${cargoConfigDir}
      # overwrite any existing config.toml
      cp --remove-destination ${storedCargoConfig} ${cargoConfigPath}

      # create .<name>_sccache cargoConfigDir (if it doesn't already exist)
      echo "Creating SCCACHE_DIR at ${cacheDir}"
      mkdir ${cacheDir}
      SCCACHE_DIR=$(realpath ${cacheDir})
      export SCCACHE_DIR=$SCCACHE_DIR
      export DEFAULT_WORKSPACE=${name}

      # initialize preferred shellHook
    '';
  }

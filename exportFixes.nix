{ lib, shellInit, ... }:
let
  escapeShellArg = lib.strings.escapeShellArg;
  flatMap = f: l: lib.lists.flatten (map f l);

  doubleQuote = x: ''"${x}"'';

  replaceComment = label: action: "# ${action} ${label}";
  fixActions = {
    delete = label: {
      find = "export ${label}(.*)$";
      replace = replaceComment label "deleted";
    };
    # when prepending path vars, we choose to prepend to the parent, so that
    # child entries always win over parent entries.
    prepend = label: {
      find = "export ${label}\=${doubleQuote "(.+)"}$";
      replace = "${replaceComment label "prepended"}\nexport ${label}\=${doubleQuote ("$$" + label + ":$1")}";
    };
  };

  prefixEcho = cmd: "echo ${escapeShellArg cmd} ; ${cmd}";

  sdCmd = find: replace:
    prefixEcho
      (
        builtins.concatStringsSep " " [
          "sd"
          (escapeShellArg find)
          (escapeShellArg replace)
          shellInit
        ]
      );
  fixCmd = fixAction: label:
  let
    find_replace = fixAction label;
  in
    with find_replace;
    prefixEcho (sdCmd find replace);

  drvAttrs = [
    "__structuredAttrs"
    "buildInputs"
    "buildPhase"
    "builder"
    "cmakeFlags"
    "configureFlags"
    "depsBuildBuild"
    "depsBuildBuildPropagated"
    "depsBuildTarget"
    "depsBuildTargetPropagated"
    "depsHostHost"
    "depsHostHostPropagated"
    "depsTargetTarget"
    "depsTargetTargetPropagated"
    "doCheck"
    "doInstallCheck"
    "installPhase"
    "mesonFlags"
    "name"
    "nativeBuildInputs"
    "out"
    "outputs"
    "patches"
    "phases"
    "preferLocalBuild"
    "propagatedBuildInputs"
    "propagatedNativeBuildInputs"
    "shell"
    "stdenv"
    "strictDeps"
    "system"
  ];
  builderVars = [
    "GZIP_NO_TIMESTAMPS"
    "NIX_BUILD_TOP"
    "NIX_LOG_FD"
    "OLDPWD"
    "TZ"
    "SHLVL"
    "PWD"
    "SOURCE_DATE_EPOCH"
    "NIX_SSL_CERT_FILE"
    "SSL_CERT_FILE"
    "SHELL"
    "HOST_PATH"
    "CONFIG_SHELL"
    "HOME"
  ] ++ (flatMap (x: [ "${x}" "${x}DIR" ]) [ "TEMP" "TMP" ]);

  pathLikes = [ "XDG_DATA_DIRS" "PATH" ];
in
builtins.concatStringsSep "\n"
  (
    [ (sdCmd "declare -x" "export") ]
    ++ (map (fixCmd fixActions.delete) (drvAttrs ++ builderVars))
    ++ (map (fixCmd fixActions.prepend) pathLikes)
  )
#++ (map (fixCmd replaceRegex.delete) (drvAttrs ++ builderVars))
#++ (map (fixCmd replaceRegex.prepend) pathLikes)

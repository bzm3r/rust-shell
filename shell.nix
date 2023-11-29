let
  sources = import ./npins;
  pkgs = import sources.nixpkgs {
    overlays = [
      (import sources.rust-overlay)
    ];
  };
in
pkgs.mkShell
{
  buildInputs = with pkgs; [
    npins
  ];

  packages = with pkgs; [
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
  ];

  shellHook = ''
    export nixpkgs=${sources.nixpkgs.outPath}
    export NIX_PATH=nixpkgs=${sources.nixpkgs.outPath}
  '';
}

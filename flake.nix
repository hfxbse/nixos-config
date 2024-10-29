{
  description = "FlakeTeX: TexLive distrubited as Nix flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = nixpkgs.legacyPackages.${system};

    # Refer to the NixOS on how to customize the TexLive installation
    # https://wiki.nixos.org/wiki/TexLive
    latex = pkgs.texliveFull;
  in
  {
    packages.compile-latex = pkgs.callPackage (import ./compile-latex.nix) { inherit latex; };
    packages.default = self.packages.${system}.compile-latex;

    apps = {
      pdflatex = {
        type = "app";
        program = "${latex}/bin/pdflatex";
      };

      pdftex = self.apps.${system}.pdflatex;

      biber = {
        type = "app";
        program = "${latex}/bin/biber";
      };
    };
  });
}

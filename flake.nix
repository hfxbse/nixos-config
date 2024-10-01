{
  description = "Auto-Editor: Efficient media analysis and rendering";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    packages.auto-editor = with pkgs; with pkgs.python3Packages; callPackage (import ./auto-editor.nix) {};

    packages.default = self.packages.${system}.auto-editor;
  });
}

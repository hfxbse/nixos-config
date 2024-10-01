{
  description = "Auto-Editor: Efficient media analysis and rendering";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in
  {

    packages.x86_64-linux.auto-editor = with pkgs; with pkgs.python3Packages; callPackage (import ./auto-editor.nix) {};

    packages.x86_64-linux.default = self.packages.x86_64-linux.auto-editor;

  };
}

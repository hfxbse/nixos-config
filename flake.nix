{
  description = "easyrom client to connect to eduroam";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    packages."${system}" = {
      easyroam = pkgs.callPackage (import ./easyroam.nix) {};
      default = self.packages."${system}".easyroam;
    };
  };
}

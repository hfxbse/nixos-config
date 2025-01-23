{
  description = "Brother HL3172cdw printer driver derivation";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in
  {
    packages.x86_64-linux.cups-brother-hl3172cdw = pkgs.callPackage (import ./cups-brother-hl3172cdw.nix) {};

    packages.x86_64-linux.default = self.packages.x86_64-linux.cups-brother-hl3172cdw;
  };
}

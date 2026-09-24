{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    let
      genModule = extraModules: { imports = extraModules ++ [ ./default.nix ]; };
    in
    {
      nixosModules.single-user = genModule [ inputs.home-manager.nixosModules.home-manager ];
      darwinModules.single-user = genModule [ inputs.home-manager.darwinModules.home-manager ];
    };
}

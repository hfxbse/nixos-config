{
  outputs = inputs: {
    nixosModules.shells = ./shells.nix;
    darwinModules.shells = ./shells.nix;
  };
}

{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = inputs: {
    nixosModules = {
      gc = ./gc.nix;
      nix-settings = ./settings.nix;
    };

    darwinModules = {
      gc = ./gc.nix;
      nix-settings = ./settings.nix;
    };
  };
}

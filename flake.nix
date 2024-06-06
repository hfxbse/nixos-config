{
  description = "Nixos configuration to manage my computer at home and my work laptop.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }@attrs: {
    nixosConfigurations.home-pc = nixpkgs.lib.nixosSystem {
      system = "x86_linux";
      specialArgs = attrs;
      modules = [ ./configuration.nix ];
    };
  };
}

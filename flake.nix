{
  description = "Nixos configuration to manage my computer at home and my work laptop.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }@attrs: {
    nixosConfigurations.home-pc = nixpkgs.lib.nixosSystem {
      specialArgs = with attrs; { 
        host = rec {
	  user.name = "fxbse";
	  user.description = "Fabian Haas";
	  name = "ice-cube";
	};
      };

      system = "x86_linux";
      modules = [ ./hosts/home-pc/configuration.nix ];
    };

    nixosConfigurations.nt-laptop = nixpkgs.lib.nixosSystem {
      specialArgs = with attrs; { 
        host = rec {
	  user.name = "fhs";
	  user.description = "Fabian Haas";
	  name = "nt-${user.name}";
	};
      };

      system = "x86_linux";
      modules = [ ./hosts/nt-laptop/configuration.nix ];
    };
  };
}
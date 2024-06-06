{
  description = "Nixos configuration to manage my computer at home and my work laptop.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }@attrs: 
  let
    defaultModules = [
      ./modules/gnome.nix
      ./modules/localization.nix
      ./modules/text-processing.nix
      ./modules/docker.nix
      ./modules/security.nix
      ./hardware/Wooting/wootility.nix
    ];
  in
  {
    nixosConfigurations.home-pc = nixpkgs.lib.nixosSystem {
      specialArgs = with attrs; { 
        host = rec {
	  user.name = "fxbse";
	  user.description = "Fabian Haas";
	  name = "ice-cube";
	};
      };

      system = "x86_linux";
      modules = defaultModules ++ [ ./hosts/home-pc/configuration.nix ];
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
      modules = defaultModules ++ [ ./hosts/nt-laptop/configuration.nix ];
    };
  };
}

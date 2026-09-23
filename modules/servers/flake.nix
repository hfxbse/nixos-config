{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-container-in-vm-fix = {
      url = "github:hfxbse/nixpkgs?ref=nixos-container-inside-vm-fix";
    };

    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    nix-minecraft.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: {
    nixosModules.servers = {
      imports = [
        ./.
        inputs.nix-minecraft.nixosModules.minecraft-servers
        "${inputs.nixpkgs-container-in-vm-fix}/nixos/modules/virtualisation/nixos-containers.nix"
      ];

      # Container in VM fix
      # See https://discourse.nixos.org/t/using-changes-from-a-nixpkgs-pr-in-your-flake/60948
      disabledModules = [ "virtualisation/nixos-containers.nix" ];

      _module.args.inputs' = inputs;

      nixpkgs.overlays = (builtins.attrValues inputs.self.overlays) ++ [
        inputs.nix-minecraft.overlays.default
      ];
    };

    overlays = {
      beszel = (import ./overlays/beszel.nix);
    };
  };
}

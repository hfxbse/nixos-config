# Quick Template

Wrapper around `nix flake init` to avoid having to type long URLs manually.

## Adding to your NixOS config with flakes

Add Quick Template to your inputs:

```nix
inputs = {
  quick-template = {
    url = "github:hfxbse/nixos-config?ref=derivation/quick-template";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

Then, parse the derivation of this flake as special arguments to your modules:

```nix
nixosConfigurations.${your-machine-name} = nixpkgs.lib.nixosSystem {
  specialArgs = with attrs; {
    quick-template = quick-template.packages.${system}.quick;
  };
};
```

The derivation can be used from here in any of your Nix files like usual:

```nix
{ quick-template, ... }:
{
  environment.systemPackages = [ quick-template ];
}
```

## Running it directly from this repository

This flake can be run directly from this repository with

```sh
nix run github:hfxbse/nixos-config/derivation/quick-template
```

though it defeats the purpose of not having to type the URL in the first place.

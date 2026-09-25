{
  outputs =
    inputs:
    let
      genModule = imports: { inherit imports; };
    in
    {
      nixosModules.gaming = genModule [ ./steam-nixos.nix ];
      homeModules.gaming = genModule [
        ./minecraft.nix
        ./steam-hm.nix
      ];
    };
}

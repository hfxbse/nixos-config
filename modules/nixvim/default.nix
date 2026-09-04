{ pkgs, lib, ... }@inputs:
{
  imports =
    map
      (
        file:
        let
          definition = (import file);
          inputs' = inputs // {
            inherit pkgs;
            lib = lib // ((import ./lib) inputs);
          };
        in
        if builtins.isFunction definition then definition inputs' else definition
      )
      [
        ./buffers.nix
        ./color-scheme.nix
        ./file-manager.nix
        ./fuzzy-finder.nix
        ./keymaps.nix
      ];
}

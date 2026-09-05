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
        ./clipboard.nix
        ./cmd.nix
        ./color-scheme.nix
        ./cursor.nix
        ./file-manager.nix
        ./fuzzy-finder.nix
        ./git.nix
        ./keymaps.nix
        ./whitespaces.nix
      ];
}

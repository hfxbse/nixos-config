{ lib, ... }@inputs:
{
  _module.args.lib' = lib.extend ((import ./lib) inputs);
  imports = [
    ./buffers.nix
    ./clipboard.nix
    ./cmd.nix
    ./color-scheme.nix
    ./completion.nix
    ./cursor.nix
    ./file-manager.nix
    ./fuzzy-finder.nix
    ./git.nix
    ./keymaps.nix
    ./lsp
    ./whitespaces.nix
  ];
}

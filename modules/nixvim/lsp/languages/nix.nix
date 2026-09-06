{ lib, pkgs, ... }:
{
  lsp.servers.nixd = {
    enable = true;
    config.settings.nixd.formatting.command = [ (lib.getExe pkgs.nixfmt) ];
  };
}

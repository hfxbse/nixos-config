{ lib, pkgs, ... }:
{
  lsp.servers = {
    kotlin_lsp = {
      enable = true;
      config.cmd = [
        (lib.getExe pkgs.kotlin-lsp)
        "--stdio"
      ];
    };
  };
}

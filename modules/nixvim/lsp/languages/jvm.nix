{ lib, pkgs, ... }:
{
  lsp.servers = {
    jdtls.enable = true;
    kotlin_lsp = {
      enable = true;
      config.cmd = [
        (lib.getExe pkgs.kotlin-lsp)
        "--stdio"
      ];
    };
  };
}

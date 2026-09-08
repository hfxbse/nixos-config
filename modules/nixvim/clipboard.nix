{ lib, pkgs, ... }:
{
  opts.clipboard = "unnamedplus";
  clipboard.providers.wl-copy.enable = lib.mkDefault (!pkgs.stdenv.hostPlatform.isDarwin);
}

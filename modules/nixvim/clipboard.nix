{ lib, ... }:
{
  opts.clipboard = "unnamedplus";
  clipboard.providers.wl-copy.enable = lib.mkDefault true;
}

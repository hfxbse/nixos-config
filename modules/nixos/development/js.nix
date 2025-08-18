{ config, lib, ... }:
let
  cfg = config.development.js;
in
{
  options.development.js.enable = lib.mkEnableOption "JavaScript development support";

  config.programs.nix-ld = lib.mkIf cfg.enable {
    # Some NPM packages contain unpatched binaries, for example Cloudflare's Wrangler CLI
    enable = lib.mkDefault true;
  };
}

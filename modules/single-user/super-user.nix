{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.single-user) username;
  inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin;
  superUserGroup =
    if isLinux then
      "wheel"
    else if isDarwin then
      "admin"
    else
      throw "Not implemented";
in
{
  config = lib.mkIf (username != null) {
    security.sudo = {
      extraConfig = ''
        Defaults:root,%${superUserGroup} timestamp_timeout=30
      '';
    }
    // lib.optionalAttrs isLinux {
      enable = lib.mkDefault true;
    };

    users.groups.${superUserGroup}.members = with config; lib.optional (isDarwin || security.sudo.enable) username;
  };
}

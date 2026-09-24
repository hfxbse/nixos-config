{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;
  cfg = config.single-user;
in
{
  options.single-user = {
    username = lib.mkOption {
      type = types.nullOr types.str;
      description = "Username assigned to the user of the machine.";
      default = null;
    };
  };

  config =
    with pkgs.stdenv.hostPlatform;
    lib.mkIf (cfg.username != null) {
      users.users.${cfg.username} = {
        home = lib.mkDefault (
          if isLinux then
            "/home/${cfg.username}"
          else if isDarwin then
            "/Users/${cfg.username}"
          else
            throw "Host platform not implemented"
        );
      }
      // lib.optionalAttrs isLinux {
        isNormalUser = true;
      };
    };
}

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.user;
in
with pkgs.stdenv.hostPlatform;
{

  options.user.name = lib.mkOption {
    description = "The main user's username for the maschine";
    type = lib.types.str;
    default = "nixos";
  };

  config.users.users.${cfg.name} =
    lib.optionalAttrs isLinux {
      isNormalUser = true;
    }
    // lib.optionalAttrs isDarwin {
      home = "/Users/${cfg.name}";
    };
}

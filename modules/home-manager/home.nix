{
  lib,
  osConfig,
  pkgs,
  ...
}:
with pkgs.stdenv.hostPlatform;
let
  user = osConfig.user.name;
in
{
  imports = [
    ./browser.nix
  ];

  home.homeDirectory = lib.mkDefault (
    if isLinux then
      /home/${user}
    else if isDarwin then
      /Users/${user}
    else
      throw "Host platform not implemented"
  );

  home.stateVersion = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
    lib.mkDefault osConfig.system.stateVersion
  );
}

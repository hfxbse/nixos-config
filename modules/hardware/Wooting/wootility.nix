{ pkgs, host, ... }:
let
  user = host.user;
in
{
  users.groups.wootility.members = [ user.name ];
  services.udev.extraRules = builtins.readFile ./wootility-udev.rules;

  users.users.${user.name}.packages = with pkgs; [
    wootility
  ];
}

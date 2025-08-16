{ ... }:
{
  imports = [ ./disk-config.nix ];
  facter.reportPath = ./facter.json;

  user.name = "fxbse";
  desktop = {
    enable = true;
    auto-rotate = true;
    login = "auto"; # No need to login againt to reach the desktop after LUKS decryption
  };

  # DO NOT CHANGE AFTER INSTALLING THE SYSTEM
  system.stateVersion = "25.05"; # Did you read the comment?
}

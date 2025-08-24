{
  config,
  pkgs,
  ...
}:
let
  user = config.user;
in
{
  imports = [ ./disk-config.nix ];
  facter.reportPath = ./facter.json;

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  # CPU frequence scaling
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "schedutil";
  };

  # Setup peripherals.
  hardware.wooting.enable = true;

  # Setup user and machine naming.
  networking.hostName = "ice-cube";
  user.name = "fxbse";

  backups = {
    enable = true;
    repositoryUrlFile = "/var/lib/backup-repository/url";
    repositoryPasswordFile = "/var/lib/backup-repository/password";
    rootPaths = [ "/home" ];
  };

  # Desktop setup.
  desktop = {
    enable = true;
    gaming.enable = true;
    login = "auto"; # No need to login againt to reach the desktop after LUKS decryption
    multimedia.videoRecording.enable = true;
  };

  # Development setup.
  development = {
    container.enable = true;
    embedded.enable = true;
    js.enable = true;
    network.enable = true;
  };

  # Enable libvirtd
  virtualisation.libvirtd.enable = true;

  users.users.${user.name} = {
    extraGroups = [ "libvirtd" ];
    packages = with pkgs; [ zotero ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}

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

  boot.defaults.secureBoot = true;
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-x86_64-v3;

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
    repository.urlFile = "/var/lib/backup-repository/url";
    repository.passwordFile = "/var/lib/backup-repository/password";
    volumePaths = [ "/home" ];
  };

  # Desktop setup.
  desktop = {
    enable = true;
    gaming.enable = true;
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

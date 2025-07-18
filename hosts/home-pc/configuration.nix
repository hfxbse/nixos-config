{
  config,
  pkgs,
  ...
}:
let
  user = config.user;
in
{
  imports = [ ./hardware-configuration.nix ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # CPU frequence scaling
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "schedutil";
  };

  # Setup user and machine naming.
  networking.hostName = "ice-cube";
  user.name = "fxbse";

  # Desktop setup.
  desktop = {
    enable = true;
    login = "auto"; # No need to login againt to reach the desktop after LUKS decryption
  };

  # Setup peripherals.
  hardware.wooting.enable = true;

  # Development setup.
  development = {
    container.enable = true;
    embedded.enable = true;
    js.enable = true;
  };

  # Setup multimedia tooling.
  multimedia.enable = true;
  multimedia.videoRecording.enable = true;

  # Enable gaming.
  gaming.enable = true;

  # Enable libritd
  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${user.name} = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
    ];

    packages = with pkgs; [
      jetbrains.idea-ultimate
      nodejs
      zotero
    ];
  };

  environment.systemPackages = with pkgs; [ ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}

# Laptop model: Lenovo Thinkpad P15 Gen 1

{ config, pkgs, host, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./nvidia.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  services.logind.lidSwitch = "lock";

  # Workplace compliance.
  workplace-compliance.enable = true;

  # Enable NTFS support.
  boot.supportedFilesystems = [ "ntfs"  ];

  # Enable nix-ld.
  programs.nix-ld.enable = true;

  # Enable libritd.
  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true;

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  # Enable networking
  networking.hostName = host.name;
  networking.networkmanager.enable = true;
  networking.networkmanager.enableStrongSwan = true;

  # Enable MTP mounting
  services.gvfs.enable = true;

  services.avahi.nssmdns4 = false; # Use the settings from below

  # settings from avahi-daemon.nix where mdns is replaced with mdns4
  system.nssModules = pkgs.lib.optional (!config.services.avahi.nssmdns4) pkgs.nssmdns;
  system.nssDatabases.hosts = with pkgs.lib; optionals (!config.services.avahi.nssmdns4) (mkMerge [
    (mkBefore [ "mdns4_minimal [NOTFOUND=return]" ]) # before resolve
    (mkAfter [ "mdns4" ]) # after dns
  ]);

  # services.avahi.nssmdns = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${host.user.name} = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
      "adbusers"
      "libvirtd"
      "dialout"    # Non-root access to serial ports for embedded development
    ];

    packages = with pkgs; [
      spotify
      gimp
      jetbrains.idea-ultimate
      inkscape
      nodejs
      vlc
      zotero
    ];
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = host.user.name;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}

{
  lib,
  config,
  ...
}:
let
  username = config.wsl.defaultUser;
in
{
  wsl.enable = true;
  wsl.defaultUser = "fabian.haas";
  security.pki.certificateFiles = [ ./ZscalerRootCertificate-2048-SHA256.crt ];
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  user.name = username;
  desktop.enable = false;
  programs.ssh.startAgent = true;

  development.container.enable = true;
  virtualisation.docker.storageDriver = lib.mkForce null;

  programs.nixvim.clipboard.providers = {
    wl-copy.enable = false;
    xclip.enable = true;
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}

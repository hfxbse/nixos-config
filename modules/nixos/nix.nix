{ ... }:
let
  randomizedDelaySec = "10min";
in
{
  nix = {
    settings.auto-optimise-store = true;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    gc = {
      automatic = true;
      options = "--delete-older-than 60d";

      persistent = true;
      inherit randomizedDelaySec;
    };
  };

  system.autoUpgrade = {
    enable = true;
    operation = "boot";

    persistent = true;
    inherit randomizedDelaySec;

    flake = "github:hfxbse/nixos-config";
    upgrade = false;  # Use versions pinned by the flake
    flags = [
      "--print-build-logs"
      "--no-update-lock-file"
    ];
  };
}

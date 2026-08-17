{ ... }:
{
  system.autoUpgrade = {
    enable = true;
    operation = "boot";

    persistent = true;
    randomizedDelaySec = "10min";

    flake = "github:hfxbse/nixos-config";
    upgrade = false; # Use versions pinned by the flake
    flags = [
      "--print-build-logs"
      "--no-update-lock-file"
    ];
  };
}

{ lib, pkgs, ... }:
{
  nix.gc =
    with pkgs.stdenv.hostPlatform;
    {
      automatic = true;
      options = "--delete-older-than 90d";
    }
    // lib.optionalAttrs isLinux {
      persistent = true;
      randomizedDelaySec = "10min";
      dates = "quarterly";
    }
    // lib.optionalAttrs isDarwin {
      interval = lib.flip map [ 1 4 7 10 ] (Month: {
        Hour = 9;
        Minute = 0;
        Day = 1;
        inherit Month;
      });
    };
}

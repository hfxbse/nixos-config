{ pkgs, ... }:
{
    services.printing = {
        enable = true;
        logLevel = "debug";
        drivers = with pkgs; [
            (callPackage ./Brother/hl3172cdw.nix {})
        ];
    };
}

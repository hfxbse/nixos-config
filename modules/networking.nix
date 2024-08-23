{ nixpkgs, ... }:
{
  nixpkgs.overlays = [
    (self: super: {
      openvpn = super.openvpn.overrideAttrs (
        final: prev: {
          version = "2.5.10";
          src = builtins.fetchurl {
            url = "https://swupdate.openvpn.net/community/releases/openvpn-${final.version}.tar.gz";
            sha256 = "sha256-0dOKP8fiAPkiH5iO8cycen1itpu1+lJ0LaEinl8k028=";
          };
        }
      );
    })
  ];
}

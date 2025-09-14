{ lib, ... }:
{
  fileSystems =
    lib.genAttrs [ "/" "/home" ] (volume: {
      device = "/dev/disk/by-uuid/bf5c7e40-af44-44dc-995f-0188d3b5b1b4";
      fsType = "btrfs";
      options = [ "subvol=@${builtins.substring 1 (builtins.stringLength volume) volume}" ];
    })
    // {
      "/boot/efi" = {
        device = "/dev/disk/by-uuid/C24D-0AD2";
        fsType = "vfat";
      };
    };

  boot.initrd.luks.devices =
    lib.genAttrs
      (map (uuid: "luks-${uuid}") [
        "59789c93-fc96-4727-bcd0-a779a7aff0cc"
        "4e58cd4b-76ee-49a4-a86c-0ad7985e8a8b"
        "d9afb347-3b4f-4606-8ca1-ddea2f9a43c3"
      ])
      (device: {
        device = "/dev/disk/by-uuid/${lib.strings.removePrefix "luks-" device}";
      });

  swapDevices = [
    { device = "/dev/disk/by-uuid/64646ebc-31c3-4808-9a4d-cc72e8ed8572"; }
  ];
}

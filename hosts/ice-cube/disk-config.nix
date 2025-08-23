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

  boot.initrd.luks.devices."luks-59789c93-fc96-4727-bcd0-a779a7aff0cc".device =
    "/dev/disk/by-uuid/59789c93-fc96-4727-bcd0-a779a7aff0cc";
  boot.initrd.luks.devices."luks-4e58cd4b-76ee-49a4-a86c-0ad7985e8a8b".device =
    "/dev/disk/by-uuid/4e58cd4b-76ee-49a4-a86c-0ad7985e8a8b";

  swapDevices = [
    { device = "/dev/disk/by-uuid/e1327672-f03e-47fb-8007-96cf293418e3"; }
  ];
}

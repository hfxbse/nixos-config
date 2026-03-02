{
  pkgs,
  ...
}:
let
  immichVolumes = [
    "/mnt/immich/memory-card"
    "/mnt/immich/usb-drive"
    "/mnt/immich/boot-drive"
  ];
in
{

  environment.systemPackages = with pkgs; [
    mergerfs
    mergerfs-tools
  ];

  backups.volumePaths = immichVolumes;
  fileSystems."/var/lib/immich/media" = {
    depends = immichVolumes;
    device = "/mnt/immich/*";
    fsType = "mergerfs";
    options = [
      "defaults"
      "fsname=mergerfs-immich"
    ];
  };

}

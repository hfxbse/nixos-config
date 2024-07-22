{
  disko.devices = {
    disk = {
      data = {
        type = "disk";
        device = "/dev/disk/by-id/mmc-YF8SD_0xfaf666b4";
        content = {
          type = "gpt";
          partitions = {
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "data-crypted";
                settings.allowDiscards = true;

                content = {
                  type = "btrfs";

                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                  };
                };
              };
            };
          };
        };
      };

      internal = {
        type = "disk";
        device = "/dev/disk/by-id/mmc-HBG4a2_0x197b0d01";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              size = "2G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                ];
              };
            };

            luks = {
              end = "-4G";
              content = {
                type = "luks";
                name = "internal-crypted";
                settings.allowDiscards = true;

                content = {
                  type = "btrfs";
                  subvolumes = {
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd:2" "noatime" ];
                    };
                  };
                };
              };
            };

            swap = {
              size = "100%";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };
          };
        };
      };
    };
  };
}

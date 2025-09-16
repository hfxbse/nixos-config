{
  disko.devices =
    let
      settings = {
        allowDiscards = true;
        bypassWorkqueues = true;
      };
      passwordFile = "/tmp/disk.key";
      mountOptions = [
        "compress=zstd"
        "noatime"
      ];
    in
    {
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
                  inherit settings passwordFile;
                  type = "luks";
                  name = "data-crypted";

                  content = {
                    type = "btrfs";

                    subvolumes = {
                      "@home" = {
                        inherit mountOptions;
                        mountpoint = "/home";
                      };
                      "@root" = {
                        inherit mountOptions;
                        mountpoint = "/root";
                      };
                      "@srv" = {
                        inherit mountOptions;
                        mountpoint = "/srv";
                      };
                      "@var" = {
                        inherit mountOptions;
                        mountpoint = "/var/lib";
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
                size = "1G";
                priority = 0;
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot/efi";
                  mountOptions = [
                    "defaults"
                  ];
                };
              };

              internal = {
                end = "-4G";
                priority = 1;
                content = {
                  inherit settings passwordFile;
                  type = "luks";
                  name = "internal-crypted";

                  content = {
                    type = "btrfs";
                    subvolumes = {
                      "@" = {
                        inherit mountOptions;
                        mountpoint = "/";
                      };
                    };
                  };
                };
              };

              zram-writeback = {
                size = "100%";
                priority = 2;
                content = {
                  inherit settings passwordFile;
                  type = "luks";
                  name = "zram-backing-crypted";
                };
              };
            };
          };
        };
      };
    };
}

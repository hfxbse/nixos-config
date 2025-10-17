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
        memory-card = {
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
                  name = "memory-card";

                  content = {
                    type = "btrfs";

                    subvolumes = {
                      "@immich" = {
                        inherit mountOptions;
                        mountpoint = "/mnt/immich/memory-card";
                      };
                    };
                  };
                };
              };
            };
          };
        };

        usb-drive = {
          type = "disk";
          device = "/dev/disk/by-id/ata-TOSHIBA_DT01ACA100_Z7O4XTHNS";
          content = {
            type = "gpt";
            partitions = {
              luks = {
                size = "100%";
                content = {
                  inherit settings passwordFile;
                  type = "luks";
                  name = "usb-drive";

                  content = {
                    type = "btrfs";

                    subvolumes = {
                      "@immich" = {
                        inherit mountOptions;
                        mountpoint = "/mnt/immich/usb-drive";
                      };
                    };
                  };
                };
              };
            };
          };
        };

        boot-drive = {
          type = "disk";
          device = "/dev/disk/by-id/ata-KINGSTON_SA400S37240G_50026B7380780074";
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
                size = "100%";
                priority = 1;
                content = {
                  inherit settings passwordFile;
                  type = "luks";
                  name = "boot-drive";

                  content = {
                    type = "btrfs";
                    subvolumes = {
                      "@" = {
                        inherit mountOptions;
                        mountpoint = "/";
                      };
                      "@root" = {
                        inherit mountOptions;
                        mountpoint = "/root";
                      };
                      "@srv" = {
                        inherit mountOptions;
                        mountpoint = "/srv";
                      };
                      "@home" = {
                        inherit mountOptions;
                        mountpoint = "/home";
                      };
                      "@var" = {
                        inherit mountOptions;
                        mountpoint = "/var";
                      };
                      "@immich" = {
                        inherit mountOptions;
                        mountpoint = "/mnt/immich/boot-drive";
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
}

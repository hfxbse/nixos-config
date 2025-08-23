{
  disko.devices.disk = {
    internal = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/efi";
              mountOptions = [ "umask=0077" ];
            };
          };

          data = {
            size = "100%";
            content = {
              type = "luks";
              name = "data";

              settings.allowDiscards = true;
              content = {
                type = "btrfs";
                subvolumes =
                  let
                    systemFileOptions = [
                      "compress-force=zstd:2"
                      "noatime"
                    ];

                    dataOptions = [
                      "compress=zstd:3"
                    ];
                  in
                  {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = systemFileOptions;
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = dataOptions;
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = systemFileOptions;
                    };
                    "/var" = {
                      mountpoint = "/var";
                      mountOptions = dataOptions;
                    };
                  };
              };
            };
          };

          swap = {
            start = "-18G";
            size = "18G";

            content = {
              type = "luks";
              name = "swap";

              settings.allowDiscards = true;
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
          };
        };
      };
    };
  };
}

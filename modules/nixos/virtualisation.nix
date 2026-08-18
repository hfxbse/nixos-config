{ config, lib, ... }:
{
  config.virtualisation = rec {
    vmVariantWithBootLoader = vmVariant;
    vmVariant = {
      # Will falsely ban the QEMU host as it tries all SSH-keys before
      # falling back to password login
      services.fail2ban.ignoreIP = [ "10.0.2.2" ];

      security.sudo.wheelNeedsPassword = false;
      services.getty.autologinUser = config.user.name;

      services.openssh.settings = {
        PasswordAuthentication = lib.mkForce true;
        PermitEmptyPasswords = lib.mkForce true;
      };

      virtualisation = {
        diskImage = null;
        diskSize = 4096;
        memorySize = 4096;
        cores = 4;
        forwardPorts = lib.mkIf config.services.openssh.enable [
          {
            from = "host";
            host.port = 2222;
            guest = {
              address = "10.0.2.15";
              port = 22;
            };
            proto = "tcp";
          }
        ];
      };
    };
  };
}

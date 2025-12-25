{
  config,
  lib,
  pkgs,
  ...
}:
let
  immichVolues = [
    "/mnt/immich/memory-card"
    "/mnt/immich/usb-drive"
    "/mnt/immich/boot-drive"
  ];
in
{
  facter.reportPath = ./facter.json;
  virtualisation.vmVariant.facter.reportPath = lib.mkForce ./facter-vm.json;
  imports = [ ./disk-config.nix ];

  boot = {
    defaults.secureBoot = true;
    loader.timeout = 2;

    kernel.sysctl = {
      "vm.swappiness" = 110;
    };

    # Hardened 6.12 LTS does not boot
    kernelPackages = pkgs.linuxPackages;
  };

  # Should reboot the system if it the system becomes unreponsive
  systemd.settings.Manager.RuntimeWatchdogSec = "30s";

  virtualisation.vmVariant.zramSwap.enable = lib.mkForce false;
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  networking.hostName = "snowball";
  virtualisation.vmVariant.networking.hostName = lib.mkForce "vm-snowball";
  user.name = "maintainer";

  # Set your time zone.
  time.timeZone = "UTC";

  backups = {
    enable = true;
    interval = 4;
    repository.urlFile = "/var/lib/backup-repository/url";
    repository.passwordFile = "/var/lib/backup-repository/password";
    snapshotPath = "/mnt/snapshots";
    volumePaths = immichVolues ++ [
      "/root"
      "/srv"
      "/home"
      "/var"
    ];
  };

  fileSystems."/var/lib/immich/media" = {
    depends = immichVolues;
    device = "/mnt/immich/*";
    fsType = "mergerfs";
    options = [
      "defaults"
      "fsname=mergerfs-immich"
    ];
  };

  services.fail2ban = {
    enable = true;
    bantime = "1d";
    bantime-increment.multipliers = "1 2 4 8 16 32 64";
    bantime-increment.rndtime = "5h";
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      LogLevel = "VERBOSE";
      PasswordAuthentication = false;
    };
  };

  networking.firewall.enable = true;

  programs.nixvim.clipboard.providers.wl-copy.enable = false;
  environment.systemPackages = with pkgs; [
    btop
    dnsutils
    htop
    mergerfs
    mergerfs-tools
    openssl
    s-tui
  ];

  system.autoUpgrade = {
    operation = lib.mkForce "switch";
    allowReboot = true;
    rebootWindow = {
      lower = "03:00";
      upper = "04:00";
    };
  };

  virtualisation.vmVariant = {
    server.externalNetworkInterface = lib.mkForce "eth0";
    server.immich.accelerationDevices = lib.mkForce [ ];
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "web@fhaas.org";
    certs."fxbse.com" = {
      domain = "*.fxbse.com";
      dnsProvider = "porkbun";
      dnsPropagationCheck = true;
      credentialsFile = "/var/fxbse.com.secrets";
    };
  };

  server =
    let
      virtualHostNames =
        with config.server;
        builtins.map (host: host.virtualHostName) [
          immich
          monitoring.webUi
          oidc
        ];
    in
    {
      enable = true;
      externalNetworkInterface = "eno1";

      monitoring = {
        enable = true;
        secretsFile = "/var/lib/beszel-agent.secrets";
        fileSystems = builtins.map ({ name, label }: "/mnt/immich/${name}__${label}") [
          {
            name = "memory-card";
            label = "Memory Card";
          }
          {
            name = "usb-drive";
            label = "USB Drive";
          }
        ];

        webUi = {
          enable = true;
          dataDir = "/var/lib/beszel-hub";
          systemStateVersion = "25.11";
          virtualHostName = "monitoring.fxbse.com";
        };
      };

      dns = {
        enable = true;
        systemStateVersion = "25.11";
        mappings = lib.genAttrs virtualHostNames (virtualHostName: [ "192.168.178.60" ]);
      };

      smart-home =
        let
          stateDir = "/var/lib/smart-home";
        in
        {
          enable = true;
          mqtt.passwordsDir = "${stateDir}/mqtt/passwords";
          mqtt.dataDir = "${stateDir}/mqtt/db";
        };

      immich = rec {
        enable = true;
        dataDir = "/var/lib/immich";
        accelerationDevices = [ "/dev/dri/renderD128" ];
        systemStateVersion = "25.11";
        virtualHostName = "gallery.fxbse.com";
        secretSettingsDir = "${dataDir}/secrets";
      };

      oidc = {
        enable = true;
        dataDir = "/var/lib/pocket-id";
        systemStateVersion = "25.11";
        secretsFile = "/var/lib/pocket-id-secrets";
        virtualHostName = "account.fxbse.com";
      };

      reverse-proxy = {
        enable = true;
        systemStateVersion = "25.11";

        virtualHosts = lib.genAttrs virtualHostNames (virtualHostName: {
          sslCertificateDir =
            let
              parts = lib.splitString "." virtualHostName;
            in
            "/var/lib/acme/${builtins.concatStringsSep "." (lib.takeEnd 2 parts)}";
        });
      };

      tunnel = {
        enable = true;
        environmentFile = "/var/lib/tunnel.secrets";
        systemStateVersion = "25.11";
      };

      permissionMappings =
        let
          ids = uid: gid: {
            user.uid = uid;
            group.gid = gid;
          };
        in
        {
          acme = ids 992 990;
          oidc = ids 990 988;
          monitoring-ui = ids 989 987;
          immich-server = ids 988 986;
          immich-db = ids 987 985;
          smart-home-mqtt = ids 986 984;
        };
    };

  # NEVER CHANGE AFTER INSTALLING THE SYSTEM
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?
}

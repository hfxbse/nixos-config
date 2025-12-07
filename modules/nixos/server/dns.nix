{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server.dns;
in
{

  options.server.dns = {
    enable = lib.mkEnableOption "a DNS server in a container";

    mappings = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = [];
    };

    systemStateVersion = lib.mkOption {
      description = "System state version used for the container. Do not change it after the container has been created.";
      type = lib.types.str;
    };
  };

  config =
    let
      container = config.containers.dns;
      blocky = container.config.services.blocky;
      unbound = container.config.services.unbound;
    in
    lib.mkIf (config.server.enable && cfg.enable) {
      server.network.dns = {
        subnetPrefix = "10.0.254";
        forwardPorts = [
          {
            port = blocky.settings.ports.dns;
            vmHostPort = 3535;
            external = true;
            protocols = [
              "tcp"
              "udp"
            ];
          }
        ];
      };

      containers.dns = {
        autoStart = true;
        privateUsers = "pick";
        additionalCapabilities = [ "CAP_NET_ADMIN" ];

        config = {
          services.resolved.enable = false;

          # Setting up a recursive resolver
          # See https://docs.pi-hole.net/guides/dns/unbound
          services.unbound = {
            enable = true;
            settings = {
              server = {
                interface = "127.0.0.1";
                port = 5335;
                do-ip4 = true;
                do-udp = true;
                do-tcp = true;
                do-ip6 = true;
                prefer-ip6 = false;
                harden-glue = true;
                harden-dnssec-stripped = true;
                use-caps-for-id = false;
                edns-buffer-size = 1232;
                prefetch = true;
                num-threads = 1;
                so-rcvbuf = "1m";

                private-address = [
                  # Ensure privacy of local IP ranges
                  "192.168.0.0/16"
                  "169.254.0.0/16"
                  "172.16.0.0/12"
                  "10.0.0.0/8"
                  "fd00::/8"
                  "fe80::/10"

                  # Ensure no reverse queries to non-public IP ranges (RFC6303 4.2)
                  "192.0.2.0/24"
                  "198.51.100.0/24"
                  "203.0.113.0/24"
                  "255.255.255.255/32"
                  "2001:db8::/32"
                ];
              };
            };
          };

          systemd.services.unbound.serviceConfig =
            let
              serviceConfig = config.systemd.services.unbound.serviceConfig or { };
            in
            {
              AmbientCapabilities = (serviceConfig.AmbientCapabilities or [ ]) ++ [
                "CAP_NET_ADMIN"
              ];

              CapabilityBoundingSet = (serviceConfig.CapabilityBoundingSet or [ ]) ++ [
                "CAP_NET_ADMIN"
              ];

            };

          services.blocky =
            let
              quad9tls = "tcp-tls:dns.quad9.net";
            in
            {
              enable = true;
              settings = {
                ports.dns = 53;

                upstreams = {
                  strategy = "strict";
                  groups.default = [
                    "127.0.0.1:${builtins.toString unbound.settings.server.port}"
                    quad9tls
                  ];
                };

                bootstrapDns = [
                  {
                    upstream = quad9tls;
                    ips = [ "9.9.9.9" ];
                  }
                ];

                customDNS.mapping = builtins.mapAttrs (
                  name: value: builtins.concatStringsSep "," value
                ) cfg.mappings;

                conditional = {
                  fallbackUpstream = false;
                  mapping."fritz.box" = "192.168.178.1";
                };

                blocking = {
                  clientGroupsBlock.default = [ "light" ];
                  denylists.light = [
                    "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/light.txt"
                    "https://gitlab.com/hagezi/mirror/-/raw/main/dns-blocklists/wildcard/light.txt"
                    "https://codeberg.org/hagezi/mirror2/raw/branch/main/dns-blocklists/wildcard/light.txt"
                  ];
                };
              };
            };

          environment.systemPackages = with pkgs; [
            dnsutils
          ];

          system.stateVersion = cfg.systemStateVersion;
        };
      };
    };
}

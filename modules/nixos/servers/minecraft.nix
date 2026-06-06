{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server.services.minecraft;
  containerName = "minecraft";
  fetchurl = pkgs.fetchurl;
  inherit (lib) types;

  dataPermissions = "0770"; # rwxrwx--- inherited from Minecraft
in
{
  options.server.services.minecraft = {
    enable = lib.mkEnableOption {
      description = "A dummy server without any services.";
    };

    port = lib.mkOption {
      description = "On which port the final DNS server is listening.";
      type = types.ints.between 0 65535;
      default = 25565;
    };

    domain = lib.mkOption {
      description = "The domain to responde to.";
      type = types.str;
    };

    dataDir = lib.mkOption {
      description = "Where the service data is stored";
      type = types.path;
      default = "/var/lib/minecraft-servers";
    };

    memory = lib.mkOption {
      type = types.submodule {
        options = {
          min = lib.mkOption {
            description = "Minimum memory allocated to the JVM heap in mebibyte (MiB)";
            type = types.ints.positive;
            default = 512;
          };

          max = lib.mkOption {
            description = "Maxium memory allocated to the JVM heap in mebibyte (MiB)";
            type = types.ints.positive;
            default = 1024;
          };
        };
      };
    };
  };

  config =
    let
      container = config.containers.${containerName};
      inherit (container.config.services) minecraft-servers;
    in
    lib.mkIf cfg.enable {
      nixpkgs.config.allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "minecraft-server"
        ];

      server = {
        containers.${containerName} = {
          dataDirMode = dataPermissions;
          dataDirs.data = {
            host.path = cfg.dataDir;
            container = with container.config.users; {
              inherit (users.${minecraft-servers.user}) uid;
              inherit (groups.${minecraft-servers.group}) gid;
              path = minecraft-servers.dataDir;
            };
          };
        };

        ddns.containers.${containerName} = {
          interface = "eth0";
          domains = [ cfg.domain ];
        };
      };

      containers.${containerName} = {
        hostBridge = config.server.ingress.bridgeNames.wan;

        config = {
          imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];

          users = with minecraft-servers; rec {
            users.${user}.uid = 651;
            groups.${group}.gid = users.${user}.uid;
          };

          services.minecraft-servers = {
            enable = true;
            eula = true;
            openFirewall = true;

            managementSystem = {
              tmux.enable = false;
              systemd-socket.enable = true;
            };

            servers.default = {
              enable = true;
              package =
                with pkgs;
                fabricServers.fabric-26_1_2.override {
                  # See https://github.com/Infinidoge/nix-minecraft/issues/211
                  jre_headless = openjdk25_headless;
                };

              symlinks = {
                mods = pkgs.linkFarmFromDrvs "mods" [
                  (fetchurl {
                    url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/E1mjhYMF/fabric-api-0.150.0%2B26.1.2.jar";
                    hash = "sha256-Q738WaIaziAjRbxMQsdR+ja4BhemHPey+MNpi4BjBdg=";
                  })
                  (fetchurl {
                    url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/GiCfpS6V/lithium-fabric-0.24.5%2Bmc26.1.2.jar";
                    hash = "sha256-VKUsTmpH7ik16EYH+LDCkmaQ6TZsif2vERVCC/G/MLQ=";
                  })
                ];
              };

              serverProperties = {
                # Server config
                enable-rcon = false;
                enable-query = false;
                management-server-enabled = false;
                server-port = cfg.port;
                use-native-transport = true;

                # Access control
                enforce-whitelist = true;
                log-ips = true;
                online-mode = true;
                white-list = true;

                # Gameplay
                force-gamemode = true;
                gamemode = "survival";
                motd = "${cfg.domain}";
                spawn-protection = 1;
              };

              jvmOpts = [
                "-Djava.net.preferIPv6Addresses=true"
                "-Djava.net.preferIPv4Stack=false"

                "-Xms${toString cfg.memory.min}M"
                "-Xmx${toString cfg.memory.max}M"
                "-XX:+UseShenandoahGC"
                "-XX:ShenandoahGCHeuristics=adaptive"
                "-XX:+UseStringDeduplication"
                "-XX:+UseCompactObjectHeaders"
              ];
            };
          };

          # The default systemd-tmpfiles.d implementation fails for owner id-mapped mounts.
          # It creates the files as root, which is not mapped.
          # Workaround to create the directory as service user directly instead.
          systemd.services = lib.pipe minecraft-servers.servers [
            builtins.attrNames
            (map (
              server:
              let
                service = "minecraft-server-${server}";
              in
              {
                name = "${service}-setup";
                value = rec {
                  before = [ "${service}.service" ];
                  requiredBy = before;
                  wantedBy = before;

                  serviceConfig = {
                    Type = "oneshot";
                    User = minecraft-servers.user;
                    Group = minecraft-servers.group;
                    ExecStart = "${lib.getExe' pkgs.coreutils "install"} -d -m ${dataPermissions} ${minecraft-servers.dataDir}/${server}";
                  };
                };
              }
            ))
            builtins.listToAttrs
          ];
        };
      };

      virtualisation.vmVariant = {
        containers.${containerName} = {
          # Connecting to the WAN interface somehow breaks internet access inside the VM
          hostBridge = lib.mkForce config.server.ingress.bridgeNames.lan;
        };

        server.ingress.forwardPorts =
          map
            (protocol: {
              inherit containerName;
              inherit (cfg) port;
              inherit protocol;
            })
            [
              "tcp"
              "udp"
            ];
      };
    };
}

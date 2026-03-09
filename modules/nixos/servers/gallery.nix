{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;
  cfg = config.server.services.gallery;
in
{
  options.server.services.gallery = {
    enable = lib.mkEnableOption {
      description = "A media gallery.";
    };

    accelerationDevices = lib.mkOption {
      description = "Paths to the devices files of the devices uses for task acceleration.";
      type = types.listOf types.path;
      default = [ ];
    };

    dataDir = lib.mkOption {
      description = "Where to store the data on the host system.";
      type = types.path;
    };

    domain = lib.mkOption {
      description = "The domain to responde to.";
      type = types.str;
    };

    oauth = {
      enable =
        lib.mkEnableOption {
          description = "use oauth rather than username+password.";
        }
        // {
          default = true;
        };

      issuerUrlFile = lib.mkOption {
        description = "Path to the file on the host that holds the issuer url.";
        type = types.path;
      };

      clientIdFile = lib.mkOption {
        description = "Path to the file on the host that holds the client identifier.";
        type = types.path;
      };

      clientSecretFile = lib.mkOption {
        description = "Path to the file on the host that holds the client secret.";
        type = types.path;
      };
    };

    smtp = {
      enable =
        lib.mkEnableOption {
          description = "use oauth rather than username+password.";
        }
        // {
          default = true;
        };

      hostFile = lib.mkOption {
        description = "Path to the file on the host that holds the SMTP host url.";
        type = types.path;
      };

      passwordFile = lib.mkOption {
        description = "Path to the file on the host that holds the SMTP password.";
        type = types.path;
      };

      # Cannot pass in via a file because it will get parsed as string not a number
      port = lib.mkOption {
        description = "Port number of the SMTP host.";
        type = types.ints.between 0 65535;
      };

      usernameFile = lib.mkOption {
        description = "Path to the file on the host that holds the SMTP username.";
        type = types.path;
      };
    };
  };

  config =
    let
      inherit (config.containers.gallery.config.services) immich postgresql;
    in
    lib.mkIf cfg.enable {
      server = {
        services.reverse-proxy.virtualHosts.${cfg.domain} = {
          containerName = "gallery";
          port = immich.port;
        };

        containers.gallery = {
          secrets =
            let
              createSecrets =
                cfg: directory:
                lib.pipe cfg [
                  (lib.filterAttrs (name: _: lib.hasSuffix "File" name))
                  (builtins.mapAttrs (
                    type: path: {
                      inherit path;
                      name = "${directory}/${lib.removeSuffix "File" type}";
                    }
                  ))
                  (lib.optionalAttrs cfg.enable)
                ];
            in
            (createSecrets cfg.oauth "oauth") // (createSecrets cfg.smtp "smtp");

          dataDirs = with config.containers.gallery.config.users; {
            database = {
              host.path = "${cfg.dataDir}/database";
              container = {
                inherit (users.postgres) uid;
                inherit (groups.postgres) gid;
                path = postgresql.dataDir;
              };
            };

            media = {
              host.path = "${cfg.dataDir}/media";
              container = {
                inherit (users.immich) uid;
                inherit (groups.immich) gid;
                path = immich.mediaLocation;
              };
            };
          };
        };
      };

      containers.gallery = {
        config =
          let
            mlDir = "/var/lib/immich-machine-learning";
          in
          {
            users = rec {
              users.immich.uid = 787;
              groups.immich.gid = users.immich.uid;
            };

            systemd.services."immich-machine-learning".serviceConfig = {
              StateDirectory = [ (lib.removePrefix "/var/lib/" mlDir) ];
            };

            services.postgresql.package = pkgs.postgresql_16;
            services.immich = {
              inherit (cfg) accelerationDevices;
              enable = true;
              openFirewall = true;
              database.enableVectors = false;
              host = "::";

              machine-learning = {
                enable = true;
                environment.MPLCONFIGDIR = mlDir;
              };

              # List of options https://docs.immich.app/install/config-file/
              # Dispite what the docs of the NixOS settings options states
              # setting a properity to null does NOT allow them to be modified
              # via the web UI.
              #
              # Credentials are loades via systemd's LoadCredential already
              settings =
                let
                  secret' = directory: name: { _secret = "/run/credentials/${directory}/${name}"; };
                in
                {
                  machineLearning.enabled = true;

                  passwordLogin.enabled = !cfg.oauth.enable;
                  oauth =
                    let
                      secret = secret' "oauth";
                    in
                    lib.mkIf cfg.oauth.enable {
                      enabled = true;
                      autoLaunch = true;
                      issuerUrl = secret "issuerUrl";
                      clientId = secret "clientId";
                      clientSecret = secret "clientSecret";
                    };

                  notifications.smtp =
                    let
                      secret = secret' "smtp";
                    in
                    lib.mkIf cfg.smtp.enable {
                      enabled = true;
                      from = "no-reply@${cfg.domain}";
                      transport = {
                        inherit (cfg.smtp) port;
                        host = secret "host";
                        ignoreCert = false;
                        password = secret "password";
                        secure = true;
                        username = secret "username";
                      };
                    };

                  server = {
                    externalDomain = "https://${cfg.domain}";
                    publicUsers = false;
                  };
                };
            };
          };
      };

      virtualisation.vmVariant.server.services.gallery = {
        oauth.enable = false;
        smtp.enable = false;
      };
    };
}

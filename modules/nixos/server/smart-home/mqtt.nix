{
  config,
  lib,
  ...
}:
let
  cfgHub = config.server.smart-home;
  cfgMqtt = cfgHub.mqtt;
in
{

  options.server.smart-home.mqtt = {
    dataDir = lib.mkOption {
      type = lib.types.path;
    };

    passwordsDir = lib.mkOption {
      type = lib.types.path;
    };
  };

  config =
    let
      mqttDbDir = "/run/mqtt/db";
      mqttPasswordsDir = "/run/mqtt/passwds";
    in
    lib.mkIf (config.server.enable && cfgHub.enable) {
      server = {
        network.smart-home.forwardPorts = [
          {
            port = 1883;
            external = true;
          }
        ];

        stateDirectories.smart-home = with cfgMqtt; [
          passwordsDir
          dataDir
        ];

        permissionMappings.smart-home-mqtt = {
          user.nameOnServer = "mosquitto";
          group.nameOnServer = "mosquitto";
          server = "smart-home";
          paths = [ mqttDbDir ];
        };
      };

      containers.smart-home = {
        bindMounts = {
          mqttPasswords = {
            mountPoint = "${mqttPasswordsDir}:idmap";
            hostPath = cfgMqtt.passwordsDir;
            isReadOnly = true;
          };

          mqttDbDir = {
            mountPoint = "${mqttDbDir}:idmap";
            hostPath = cfgMqtt.dataDir;
            isReadOnly = false;
          };
        };

        config = {
          ids = with config.server.permissionMappings.smart-home-mqtt; {
            uids.mosquitto = lib.mkForce user.uid;
            gids.mosquitto = lib.mkForce group.gid;
          };

          services.mosquitto = {
            enable = true;
            settings.persistence_location = mqttDbDir;
            listeners = [
              {
                users = {
                  hub = {
                    acl = [ "readwrite #" ];
                    passwordFile = "${mqttPasswordsDir}/hub";
                  };

                  solar = {
                    acl = [ "readwrite #" ];
                    passwordFile = "${mqttPasswordsDir}/solar";
                  };
                };
              }
            ];
          };
        };
      };
    };
}

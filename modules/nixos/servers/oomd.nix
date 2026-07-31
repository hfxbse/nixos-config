{
  config,
  lib,
  ...
}:
let
  cfg = config.servers.oomd;
in
{
  options.servers.oomd.limit = lib.mkOption {
    description = "Memory pressure limit in percent before killing services on the server";
    type = lib.types.ints.between 0 100;
    default = 80;
  };

  config = lib.mkIf (builtins.length (builtins.attrNames config.server.containers) != 0) {
    systemd.oomd = {
      enable = true;
    };

    systemd.slices."machine".sliceConfig = {
      ManagedOOMSwap = "kill";
      ManagedOOMMemoryPressure = "kill";
      ManagedOOMMemoryPressureLimit = "${toString cfg.limit}%";
      ManagedOOMMemoryPressureDurationSec = "10sec";
    };
  };
}

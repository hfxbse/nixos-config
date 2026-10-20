{
  jq,
  lib,
  opencode,
  sandbox-runtime,
  writeShellScriptBin,
  writeText,
  ...
}:
let
  srt = lib.getExe sandbox-runtime;
  oc = lib.getExe opencode;
  jq' = lib.getExe jq;

  writeJson = name: attrs: writeText name (toString (lib.toJSON attrs));

  srtConfigTemplate = writeJson "srt-settings.json" {
    allowPty = true;
    filesystem = {
      allowRead = [
        "."
        "/nix/store"
        "/nix/var"
        "/private/var/run"
        "/run"
        "/tmp"
      ];
      denyRead = [
        "/"
        "/tmp"
      ];
      allowWrite = [ "." ];
      denyWrite = [ ];
    };

    network = {
      allowedDomains = [ ];
      deniedDomains = [ ];
      allowLocalBinding = false;
    };
  };

  ocConfig = writeJson "opencode-config.json" { };
in
writeShellScriptBin "opencode" ''
  WORKING_DIR=$(mktemp -d /tmp/opencode.XXXXXXX);
  WORKING_DIR_DENY="\"$WORKING_DIR/*\", \"$WORKING_DIR/*/**\""
  echo "Using $WORKING_DIR as data directory";

  FAKE_HOME="$WORKING_DIR/data";
  FAKE_HOME_ALLOW="\"$FAKE_HOME\"";
  mkdir -p $FAKE_HOME;

  SRT_SETTINGS="$WORKING_DIR/srt-settings.json"
  ${jq'} "
    .filesystem.allowRead = (.filesystem.allowRead // []) + [$FAKE_HOME_ALLOW] |
    .filesystem.allowWrite = (.filesystem.allowWrite // []) + [$FAKE_HOME_ALLOW] |
    .filesystem.denyRead = (.filesystem.denyRead // []) + [$WORKING_DIR_DENY]
  " ${srtConfigTemplate} > $SRT_SETTINGS

  OPENCODE_CONFIG=${ocConfig} ${srt} --settings "$SRT_SETTINGS" --\
      HOME="$FAKE_HOME" XDG_DATA_HOME="$FAKE_HOME" TMPDIR="$FAKE_HOME/tmp" ${oc} "$@"
''

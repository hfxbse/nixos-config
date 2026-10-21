{
  fetchFromGitHub,
  jq,
  lib,
  llama-cpp,
  opencode,
  sandbox-runtime,
  writeShellScriptBin,
  writeText,
  ...
}:
let
  jq' = lib.getExe jq;
  llama = lib.getExe' llama-cpp "llama-server";
  oc = lib.getExe opencode;
  srt = lib.getExe sandbox-runtime;

  opencode-llama-cpp = fetchFromGitHub {
    owner = "llessi06";
    repo = "opencode-llama.cpp";
    rev = "v0.2.0";
    hash = "sha256-wybyHN3qtH9qhhd8Ok91ZiK1LJTSWqwWXgNs5nbIC8I=";
  };

  llamaHost = "localhost";
  llamaPort = "9931";

  writeJson = name: attrs: writeText name (toString (lib.toJSON attrs));

  srtConfigTemplate = writeJson "srt-settings.json" {
    allowPty = true;
    filesystem = {
      allowRead = [
        "."
        "/bin"
        "/nix/store"
        "/nix/var"
        "/private/var/run"
        "/private/etc/hosts"
        "/etc"
        "/run"
        "/tmp"
      ];
      denyRead = [
        "/"
        "/tmp"
        "/etc/**"
      ];
      allowWrite = [ "." ];
      denyWrite = [ ];
    };

    network = {
      allowedDomains = [ ];
      deniedDomains = [ ];
      allowLocalBinding = true;
    };
  };

  ocConfigTemplate = writeJson "opencode-config.json" {
    lsp = true;
    plugin = [ opencode-llama-cpp ];
    provider = {
      "llama.cpp" = {
        npm = "@ai-sdk/openai-compatible";
        name = "llama.cpp";
        options.apiKey = "not-used";
      };
    };
  };
in
writeShellScriptBin "opencode" ''
  WORKING_DIR=$(mktemp -d /tmp/opencode.XXXXXXX);
  WORKING_DIR_DENY="\"$WORKING_DIR/*\", \"$WORKING_DIR/*/**\""
  echo "Using $WORKING_DIR as data directory";

  ${llama} --host ${llamaHost} --port ${llamaPort} > "$WORKING_DIR/llama.log" 2>&1 &

  FAKE_HOME="$WORKING_DIR/data";
  mkdir -p $FAKE_HOME;

  OPENCODE_CONFIG="$WORKING_DIR/opencode-config.json"
  SRT_SETTINGS="$WORKING_DIR/srt-settings.json"

  RW_ALLOW="\"$FAKE_HOME\""
  R_ALLOW="$RW_ALLOW, \"$OPENCODE_CONFIG\""
  ${jq'} "
    .filesystem.allowRead = (.filesystem.allowRead // []) + [$R_ALLOW ] |
    .filesystem.allowWrite = (.filesystem.allowWrite // []) + [$RW_ALLOW] |
    .filesystem.denyRead = (.filesystem.denyRead // []) + [$WORKING_DIR_DENY]
  " ${srtConfigTemplate} > $SRT_SETTINGS

  ${jq'} "
    .provider.\"llama.cpp\".options.baseURL = \"http://${llamaHost}:${llamaPort}/v1\"
  " ${ocConfigTemplate} > $OPENCODE_CONFIG

   ${srt} --settings "$SRT_SETTINGS" --\
      HOME="$FAKE_HOME" XDG_DATA_HOME="$FAKE_HOME" TMPDIR="$FAKE_HOME/tmp" OPENCODE_CONFIG=$OPENCODE_CONFIG ${oc} "$@"
''

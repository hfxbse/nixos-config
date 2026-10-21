{
  fastcrw,
  fetchFromGitHub,
  jq,
  lib,
  lightpanda,
  llama-cpp,
  mcp-proxy,
  opencode,
  sandbox-runtime,
  searxng,
  writeShellScriptBin,
  writeText,
  ...
}:
let
  crw = lib.getExe fastcrw;
  jq' = lib.getExe jq;
  llama = lib.getExe' llama-cpp "llama-server";
  lp = lib.getExe lightpanda;
  oc = lib.getExe opencode;
  sear = lib.getExe searxng;
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
    filesystem = {
      allowRead = [
        "."
        "/bin"
        "/nix/store"
        "/nix/var"
        "/private/var/run"
        "/private/etc/hosts"
        "/private/etc/ssl"
        "/etc"
        "/etc/ssl"
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

  crwPort = "3000";
  ocConfigTemplate = writeJson "opencode-config.json" {
    lsp = true;
    plugin = [ opencode-llama-cpp ];
    skills = [ "${fastcrw.src}/skills" ];
    provider = {
      "llama.cpp" = {
        npm = "@ai-sdk/openai-compatible";
        name = "llama.cpp";
        options.apiKey = "not-used";
      };
    };
    mcp.servers = {
      fastcrw = {
        type = "remote";
        url = "http://localhost:3000/mcp";
      };
    };
  };

  searxngConfigTemplate = writeJson "searxng-settings.yml" {
    use_default_settings = true;
    server = {
      bind_address = "localhost";
      port = 8088;
    };
    search.formats = [
      "html"
      "json"
    ];
  };
in
writeShellScriptBin "opencode" ''
  set -m
  WORKING_DIR=$(mktemp -d /tmp/opencode.XXXXXXX);
  WORKING_DIR_DENY="\"$WORKING_DIR/*\", \"$WORKING_DIR/*/**\""
  echo "Using $WORKING_DIR as temporary data directory";

  LLAMA_CMD="${llama} --host ${llamaHost} --port ${llamaPort} "$LLAMA_OPTIONS""
  echo "Starting llama-server: $LLAMA_CMD"
  eval "$LLAMA_CMD" &

  export SEARXNG_SETTINGS_PATH="$WORKING_DIR/searxng-settings.yml"
  ${jq'} "
    .server.secret_key= \"$(openssl rand -base64 32)\"
  " ${searxngConfigTemplate} > $SEARXNG_SETTINGS_PATH
  ${sear} &


  if [ -n "$EXTRACTION_LLM" ]; then
    CRW_LLM_OPS="--env CRW_EXTRACTION__LLM__PROVIDER openai-compatible \
    --env CRW_EXTRACTION__LLM__BASE_URL http://localhost:9931/v1 \
    --env CRW_EXTRACTION__LLM__MODEL "$EXTRACTION_LLM" \
    --env CRW_EXTRACTION__LLM__API_KEY dummy \
    --env CRW_EXTRACTION__LLM__TIMEOUT_MS 300000 \
    ";
  fi

  ${lp} serve --host 127.0.0.1 --port 9222 --block-private-networks --obey-robots &
  FASTCRW_CMD="${lib.getExe mcp-proxy} --port=${crwPort} --allow-origin='*' \
    --env CRW_SEARCH__SEARCH_BACKEND_URL http://localhost:8088 \
    --env CRW_RENDERER__LIGHTPANDA__WS_URL ws://127.0.0.1:9222 \
    "$CRW_LLM_OPS" \
    ${crw} mcp"
  echo "Starting fastcrw MCP: $FASTCRW_CMD";
  eval "$FASTCRW_CMD" &

  if [ -n "$FAKE_HOME" ]; then
    TARGET_HOME="$WORKING_DIR/data";
  else
    TARGET_HOME="''${XDG_DATA_HOME:-"$HOME/.local/share/opencode"}";
    echo "Persisting data at $TARGET_HOME"
  fi
  mkdir -p "$TARGET_HOME"

  OPENCODE_CONFIG="$WORKING_DIR/opencode-config.json"
  SRT_SETTINGS="$WORKING_DIR/srt-settings.json"
  TARGET_TMP_DIR="$WORKING_DIR/tmp"
  mkdir -p "$TARGET_TMP_DIR"

  RW_ALLOW="\"$TARGET_HOME\", \"$TARGET_TMP_DIR\""
  R_ALLOW="$RW_ALLOW, \"$OPENCODE_CONFIG\""
  ${jq'} "
    .filesystem.allowRead = (.filesystem.allowRead // []) + [$R_ALLOW ] |
    .filesystem.allowWrite = (.filesystem.allowWrite // []) + [$RW_ALLOW] |
    .filesystem.denyRead = (.filesystem.denyRead // []) + [$WORKING_DIR_DENY]
  " ${srtConfigTemplate} > $SRT_SETTINGS

  ${jq'} "
    .provider.\"llama.cpp\".options.baseURL = \"http://${llamaHost}:${llamaPort}/v1\"
  " ${ocConfigTemplate} > $OPENCODE_CONFIG

   ${srt} --debug --settings "$SRT_SETTINGS" --\
      HOME="$TARGET_HOME" TMPDIR="$TARGET_TMP_DIR" OPENCODE_CONFIG=$OPENCODE_CONFIG ${oc} web --print-logs "$@"
''

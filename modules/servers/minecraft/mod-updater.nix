{
  curl,
  gawk,
  jq,
  lib,
  openssl,
  writeShellScriptBin,
  xxd,
  ...
}:
let
  awk' = lib.getExe gawk;
  curl' = lib.getExe curl;
  jq' = lib.getExe jq;
  xxd' = lib.getExe xxd;
  openssl' = lib.getExe openssl;
in
writeShellScriptBin "update-mc-mods" ''
  set -e;

  if [ "$#" -ne 3 ]; then
    echo "Error: Exactly three arguments expected"
    echo "Usage: $(basename "$0") <minecraft-version> <mod-loader> <file-path>"
    exit 1
  fi

  MINECRAFT_VERSION="$1"
  LOADER="$2"
  MODS=$(<"$3")
  for mod in $(echo "$MODS" | ${jq'} -r 'keys[]'); do
    url=$(echo "$MODS" | ${jq'} -r --arg m "$mod" '.[$m].url')
    id=$(echo "$url" | ${awk'} -F'/data/' '{print $2}' | ${awk'} -F'/' '{print $1}')

    versions=$(
      ${curl'} \
          "https://api.modrinth.com/v2/project/$id/version" -G \
          --data-urlencode "game_versions=[\"$MINECRAFT_VERSION\"]" \
          --data-urlencode "loaders=[\"$LOADER\"]" \
          -sSLA "''${MOD_UPDATER_AGENT:-nix-mod-updater}"
    )
    if [ "$(echo "$versions" | ${jq'} '.[0]')" = "null" ]; then
      echo "Error: Mod https://modrinth.com/project/$id incompatible with specified version or loader"
      exit 1
    fi

    url=$(echo "$versions" | ${jq'} -r '.[0].files[] | select(.primary == true) | .url')
    hash="sha512-$(
      echo "$versions" \
        | ${jq'} -r '.[0].files[] | select(.primary == true) | .hashes.sha512' \
        | ${xxd'} -r -p \
        | ${openssl'} base64 -A
    )"

    MODS=$(
      echo "$MODS" \
      | ${jq'} --arg m "$mod" --arg u "$url" --arg h "$hash" '.[$m].url = $u | .[$m].hash = $h'
    )
  done

  echo -e "$MODS"
''

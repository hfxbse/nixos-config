{
  lib,
  nix,
  writeShellScriptBin,
  yq,
  ...
}:
writeShellScriptBin "ci-version-checker" /* bash */ ''
  ${lib.getExe yq} -r 'to_entries[] | "\(.key)=\(.value)"' "$1" | while IFS='=' read -r key value; do
    echo "- $key $(${lib.getExe nix} eval --raw $value)";
  done
''

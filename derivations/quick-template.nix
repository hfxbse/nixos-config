{
  writeShellScriptBin,
  ...
}:
writeShellScriptBin "quick" ''
  set -e;

  if [ "$#" -eq 0 ]; then
    echo "Usage: $(basename "$0") <template name> [OPTIONS...]";
    exit 1;
  fi

  type="$1";
  shift;

  if [ "$type" == "latex" ]; then
    nix flake init -t github:hfxbse/flaketex-base-template "$@";
  else
    nix flake init -t "github:hfxbse/nixos-config#$type" "$@";
  fi
''

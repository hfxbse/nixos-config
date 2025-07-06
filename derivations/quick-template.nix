{
  writeShellScriptBin
}:
writeShellScriptBin "quick" ''
  set -e;

  if [ "$#" -eq 0 ]; then
    echo "Usage: $(basename "$0") <template name> [OPTIONS...]";
    exit 1;
  fi

  if [ "$1" == "latex" ]; then
    shift;
    nix flake init -t github:hfxbse/flaketex-base-template $@;
  else
    nix flake init -t github:hfxbse/nixos-config/template/$@;
  fi
''

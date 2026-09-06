{ lib, ... }@inputs:
final: prev:
lib.genAttrs [ "mkKeymapsOption" "mkKeymaps" ] (name: (import ./${name}.nix) (inputs // lib))

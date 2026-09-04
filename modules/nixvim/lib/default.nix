{ lib, ... }@inputs:
lib.genAttrs [ "mkKeymapsOption" "mkKeymaps" ] (name: (import ./${name}.nix) (inputs // lib))

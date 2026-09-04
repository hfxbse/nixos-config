{ lib, ... }:
let
  inherit (lib) types;
in
_:
lib.mkOption {
  default = [ ];
  type = types.listOf (
    types.submodule {
      options = {
        mode = lib.mkOption { };
        key = lib.mkOption {
          type = types.str;
        };
      };
    }
  );
}

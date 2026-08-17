{
  config,
  lib,
  pkgs,
  ...
}:
let
  editorPath = lib.getExe pkgs.nvim;
in
{
  programs.nixvim = {
    imports = [ ./. ];
    nixpkgs.pkgs = pkgs;
    viAlias = true;
  };

  environment = lib.mkIf config.programs.nixvim.enable {
    variables = lib.genAttrs [ "VISUAL" "EDITOR" ] (name: editorPath);
  };
}

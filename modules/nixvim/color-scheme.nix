{ lib, pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) isLinux;
in
{
  opts = {
    termguicolors = true;
  };

  colorschemes.one.enable = true;
  plugins.treesitter = {
    enable = true;
    settings.highlight.enable = true;
  };

  extraPackages = lib.mkIf isLinux (with pkgs; [ dbus ]);
  extraPlugins = with pkgs.vimPlugins; [ auto-dark-mode-nvim ];
  extraConfigLua =
    with lib;
    optionalString (nixvim.enableExceptInTests || isLinux) ''
      require("auto-dark-mode").setup({})
    '';
}

{ lib, pkgs, ... }:
{
  opts = {
    termguicolors = true;
  };

  colorschemes.one.enable = true;
  plugins.treesitter = {
    enable = true;
    settings.highlight.enable = true;
  };

  extraPackages = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (with pkgs; [dbus]);
  extraPlugins = with pkgs.vimPlugins; [ auto-dark-mode-nvim ];
  extraConfigLua = ''
    require("auto-dark-mode").setup({})
  '';
}

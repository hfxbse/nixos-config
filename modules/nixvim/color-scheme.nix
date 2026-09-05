{ pkgs, ... }:
{
  opts = {
    termguicolors = true;
  };

  colorschemes.one.enable = true;
  plugins.treesitter = {
    enable = true;
    settings.highlight.enable = true;
  };

  extraPlugins = with pkgs.vimPlugins; [ auto-dark-mode-nvim ];
}

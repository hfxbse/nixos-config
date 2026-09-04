{ pkgs, ... }:
let
  inherit (pkgs) fetchFromGitHub vimUtils;
  jb = vimUtils.buildVimPlugin {
    name = "jb.nvim";
    src = fetchFromGitHub {
      owner = "nickkadutskyi";
      repo = "jb.nvim";
      rev = "984139426dbc1af955fab83b964712d36db7213d";
      hash = "sha256-rlS/kEwPWMDynTmFAWaBkIJlPFdPBm89pClJsUBz5P0=";
    };
  };
in
{
  extraPlugins = [ jb ];
  extraConfigLua = ''
    vim.cmd("colorscheme jb")
  '';

  opts = {
    termguicolors = true;
  };

  plugins.treesitter = {
    enable = true;
    settings.highlight.enable = true;
  };
}

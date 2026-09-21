{ pkgs, ... }:
let
  inherit (pkgs) fetchFromGitHub vimUtils;

  yeet-nvim = vimUtils.buildVimPlugin rec {
    name = "yeet.nvim";
    src = fetchFromGitHub {
      owner = "samharju";
      repo = name;
      rev = "5e626267e15938777a628c715e1770f84f213f52";
      hash = "sha256-PsMTunKvcM4Jrt4mjIdPdNRgnnkP9YSXL7qA+rVsaIA=";
    };
  };
in
{
  extraPlugins = [ yeet-nvim ];
  extraConfigLua = ''
    require('yeet').setup({});
  '';
}

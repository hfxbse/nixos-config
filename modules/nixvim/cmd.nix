{ pkgs, ... }:
let
  inherit (pkgs) fetchFromGitHub vimUtils;

  ed-cmd-nvim = vimUtils.buildVimPlugin rec {
    name = "ed-cmd.nvim";
    src = fetchFromGitHub {
      owner = "smilhey";
      repo = name;
      rev = "0ec9d3df51739c48c800c15a600396b785c346fb";
      hash = "sha256-MFzFrVi9FrKUg7VpWeAzAham0xIctd95UpJT8HIcR1o=";
    };
  };
in
{
  opts.wildmode = "full:longest,full";
  extraPlugins = [ ed-cmd-nvim ];
  extraConfigLua = ''
    require("ed-cmd").setup({})
  '';
}

{
  lib,
  pkgs,
  ...
}:
let
  buildVimPlugin = pkgs.vimUtils.buildVimPlugin;
  fetchFromGitHub = pkgs.fetchFromGitHub;

  yeet = buildVimPlugin {
    name = "yeet";
    src = fetchFromGitHub {
      owner = "samharju";
      repo = "yeet.nvim";
      rev = "31046346b4f146e337c3f1fda604f0e1e25e1df7";
      hash = "sha256-4kUnzGEgvg6E9JDSeTZ9kqwN5QBO+wN4/wWo/x5zbaw=";
    };
  };
in
{
  imports = [
    ./theme.nix
    ./telescope.nix
    ./completion.nix
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;

    clipboard.providers.wl-copy.enable = lib.mkDefault true;

    keymaps = [
      {
        mode = [ "n" ];
        key = "<C-A-l>";
        action = "<cmd>lua vim.lsp.buf.format()<cr>";
      }
      {
        mode = [ "n" ];
        key = "tt";
        action = "<cmd>vertical botright terminal<cr>";
      }
      {
        mode = [ "n" ];
        key = "mc";
        action = "<cmd>bd<cr>";
      }
      {
        mode = [ "n" ];
        key = "mC";
        action = "<cmd>bd!<cr>";
      }
      {
        mode = [ "n" ];
        # technically should be mn but mm feels so much better
        key = "mm";
        action = "<cmd>bnext<cr>";
      }
      {
        mode = [ "n" ];
        key = "mp";
        action = "<cmd>bprevious<cr>";
      }
    ];

    opts = {
      number = true;

      clipboard = "unnamedplus";
      wildmode = "list:longest";

      expandtab = true;
      autoindent = true;
      smarttab = true;
      tabstop = 4;
      shiftwidth = 4;
    };

    plugins = {
      nvim-autopairs.enable = true;
      gitsigns.enable = true;
      trim.enable = true;
    };

    extraPlugins = [ yeet ];
    extraConfigLua = ''
      require('yeet').setup({})
    '';
  };
}

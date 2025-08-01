{
  config,
  pkgs,
  ...
}:
let
  cfg = config.programs.nixvim;
in
{
  programs.nixvim = {
    colorschemes.catppuccin = {
      enable = true;
      settings = {
        background = {
          light = "latte";
          dark = "mocha";
        };
        flavor = "auto";

        integrations = {
          gitsigns = cfg.plugins.gitsigns.enable;
          treesitter = true;
        };
      };
    };

    plugins = {
      lualine.enable = true;

      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
        };
      };

      web-devicons.enable = true;
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}

{ pkgs, host, nixvim, ... }: {
  programs.git.enable = true;
  programs.git.config = {
    init.defaultBranch = "main";
    core.editor = "nvim";
    user.name = host.user.description;
  };

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;

    keymaps = [
      {
        mode = [ "n" ];
        key = "T";
        action = "<cmd>Telescope find_files<cr>";
      }
      {
        mode = [ "n" ];
        key = "sT";
        action = "<cmd>Telescope git_status<cr>";
      }
      {
        mode = [ "n" ];
        key = "gT";
        action = "<cmd>Telescope live_grep<cr>";
      }
    ];

    opts = {
      number = true;

      wildmode = "list:longest";

      expandtab = true;
      autoindent = true;
      smarttab = true;
      tabstop = 4;
      shiftwidth = 4;
    };

    colorschemes.catppuccin = {
      enable = true;
      settings = {
        background = {
          light = "latte";
          dark = "mocha";
        };
        flavor = "auto";

        integrations = {
          gitsigns = true;
          treesitter = true;
        };
      };
    };

    plugins = {
      vimtex.enable = true;
      nvim-autopairs.enable = true;
      gitsigns.enable = true;
      trim.enable = true;

      web-devicons.enable = true;
      telescope = {
        enable = true;
        extensions = {
          live-grep-args.enable = true;
        };
      };

      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
        };
      };
    };

    extraPlugins = with pkgs.vimPlugins; [
      vim-grammarous
    ];

    extraPackages = with pkgs; [
      ripgrep
    ];
  };


  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono"]; })
  ];
}

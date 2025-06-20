{ config, lib, nixvim, pkgs, ... }: {
  options.user.fullName = lib.mkOption {
    description = "The full name of the user of the machine";
    type = lib.types.str;
  };

  config = {
    programs.git.enable = true;
    programs.git.config = {
      init.defaultBranch = "main";
      core.editor = "nvim";
      user.name = config.user.fullName;
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

          settings = let
            hiddenFiles = [
              "--hidden"
              "--glob"
              "!**/.git/*"
            ];
          in {
            defaults.vimgrep_arguments = [
              "rg"
              "--color=never"
              "--no-heading"
              "--with-filename"
              "--line-number"
              "--column"
            ] ++ hiddenFiles;
            pickers.find_files.find_command = [
              "rg"
              "--files"
            ] ++ hiddenFiles;
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
        fd
        ripgrep
      ];
    };

    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
    ];
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkKeymaps mkKeymapsOption;
  cfg = config.fuzzy-finder;
in
{
  options.fuzzy-finder.keymaps = {
    view.buffers = mkKeymapsOption { };
    view.changes = mkKeymapsOption { };
    view.project = mkKeymapsOption { };
    view.text = mkKeymapsOption { };
  };

  config = {
    keymaps =
      mkKeymaps "<CMD>Telescope find_files<cr>" cfg.keymaps.view.project
      ++ mkKeymaps "<CMD>Telescope git_status<cr>" cfg.keymaps.view.changes
      ++ mkKeymaps "<CMD>Telescope live_grep<cr>" cfg.keymaps.view.text
      ++ mkKeymaps "<CMD>Telescope buffers<cr>" cfg.keymaps.view.buffers;

    plugins.telescope = {
      enable = true;
      extensions = {
        live-grep-args.enable = true;
      };

      settings =
        let
          hiddenFiles = [
            "--hidden"
            "--glob"
            "!**/{.git,node_modules}/*"
          ];
        in
        {
          defaults.vimgrep_arguments = [
            "rg"
            "--color=never"
            "--no-heading"
            "--with-filename"
            "--line-number"
            "--column"
          ]
          ++ hiddenFiles;
          pickers.find_files.find_command = [
            "rg"
            "--files"
          ]
          ++ hiddenFiles;
        };
    };

    extraPackages = with pkgs; [
      fd
      ripgrep
    ];

  };
}

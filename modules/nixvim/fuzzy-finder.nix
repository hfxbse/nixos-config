{
  config,
  lib',
  pkgs,
  ...
}:
let
  inherit (lib') mkKeymaps mkKeymapsOption;
  cfg = config.fuzzy-finder;
in
{
  options.fuzzy-finder.keymaps = {
    view.buffers = mkKeymapsOption { };
    view.changes = mkKeymapsOption { };
    view.diagnostics = mkKeymapsOption { };
    view.marks = mkKeymapsOption { };
    view.project = mkKeymapsOption { };
    view.text = mkKeymapsOption { };
  };

  config = {
    keymaps =
      mkKeymaps "<CMD>Telescope find_files<cr>" cfg.keymaps.view.project
      ++ mkKeymaps "<CMD>Telescope git_status<cr>" cfg.keymaps.view.changes
      ++ mkKeymaps "<CMD>Telescope diagnostics<cr>" cfg.keymaps.view.diagnostics
      ++ mkKeymaps "<CMD>Telescope marks<cr>" cfg.keymaps.view.marks
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
          defaults= {
            layout_strategy = "flex";
            layout_config = {
              width.__raw = "{ 0.925, max = 260 }";
              flex.flip_columns = 160;
              vertical.preview_cutoff = 30;
              horizontal.preview_width.__raw = let resultWidth = 80; in ''
                function(_, max_columns, _)
                  return max_columns - ${toString resultWidth} - 2  -- 2 cols for the border between panes
                end;
              '';
            };
            vimgrep_arguments = [
              "rg"
                "--color=never"
                "--no-heading"
                "--with-filename"
                "--line-number"
                "--column"
            ]
            ++ hiddenFiles;
          };

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

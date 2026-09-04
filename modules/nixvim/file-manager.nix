{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkKeymaps mkKeymapsOption;
  cfg = config.file-manager;
in
{
  options.file-manager.keymaps = {
    view.project = mkKeymapsOption { };
    view.changes = mkKeymapsOption { };
    view.buffers = mkKeymapsOption { };
  };

  config = {
    globals = {
      # Disable builtin plugin netrw by pretending it is already loaded
      loaded_netrwPlugin = 1;
      loaded_netrw = 1;
    };

    keymaps =
      mkKeymaps "<CMD>Neotree reveal=true<cr>" cfg.keymaps.view.project
      ++ mkKeymaps "<CMD>Neotree source=git_status<cr>" cfg.keymaps.view.changes
      ++ mkKeymaps "<CMD>Neotree source=buffers<cr>" cfg.keymaps.view.buffers;

    plugins = {
      neo-tree = {
        enable = true;
        settings = {
          window.position = "current";
          filesystem.filtered_items.visible = true;
        };
      };

      web-devicons.enable = true;
    };
  };
}

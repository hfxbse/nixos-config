{
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  cfg = config.file-manager;

  mkKeymapOption =
    _:
    lib.mkOption {
      default = [ ];
      type = types.listOf (
        types.submodule {
          options = {
            mode = lib.mkOption { };
            key = lib.mkOption {
              type = types.str;
            };
          };
        }
      );
    };
in
{
  options.file-manager.keymaps = {
    view.project = mkKeymapOption { };
    view.changes = mkKeymapOption { };
    view.buffers = mkKeymapOption { };
  };

  config = {
    globals = {
      # Disable builtin plugin netrw by pretending it is already loaded
      loaded_netrwPlugin = 1;
      loaded_netrw = 1;
    };

    keymaps =
      let
        mkKeymaps = action: map (keymap: keymap // { inherit action; });
      in
      mkKeymaps "<CMD>Neotree<cr>" cfg.keymaps.view.project
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

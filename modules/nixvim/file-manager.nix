{
  config,
  lib,
  pkgs,
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
    open = mkKeymapOption { };
  };

  config = {
    globals = {
      # See https://vimhelp.org/pi_netrw.txt.html#netrw-var
      netrw_banner = 0;
      netrw_browse_split = 0;
      netrw_hide = 0;
      netrw_liststyle = 3;
    };

    keymaps =
      let
        mkKeymaps = action: map (keymap: keymap // { inherit action; });
      in
      mkKeymaps "<CMD>Explore<cr>" cfg.keymaps.open;

    plugins.web-devicons.enable = true;
    extraPlugins = with pkgs.vimPlugins; [
      netrw-nvim
    ];

    extraConfigLua = ''
      require("netrw").setup({
        -- File icons to use when `use_devicons` is false or if
        -- no icon is found for the given file type.
        icons = {
          symlink = '',
          directory = '',
          file = '',
        },
        -- Uses mini.icon or nvim-web-devicons if true, otherwise use the file icon specified above
        use_devicons = true
      })
    '';
  };
}

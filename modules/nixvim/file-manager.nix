{
  config,
  lib',
  pkgs,
  ...
}:
let
  inherit (lib') mkKeymaps mkKeymapsOption;
  inherit (pkgs) fetchFromGitHub vimUtils;
  cfg = config.file-manager;

  nvim-lsp-file-operations = vimUtils.buildVimPlugin rec {
    name = "nvim-lsp-file-operations";
    dependencies = with pkgs.vimPlugins; [ plenary-nvim ];
    src = fetchFromGitHub {
      repo = name;
      owner = "antosha417";
      rev = "276f096ef324c140d00bd0188a0e70382e156771";
      hash = "sha256-FObv42EGkIao2Rmq9CG+G4JsntO+00CFNaNIXc7IK7A=";
    };
  };
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

    extraPlugins = [ nvim-lsp-file-operations ];
    extraConfigLua = ''
      require("lsp-file-operations").setup();
    '';
  };
}

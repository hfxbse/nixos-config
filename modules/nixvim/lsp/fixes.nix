{
  config,
  lib',
  pkgs,
  ...
}:
let
  inherit (lib') mkKeymaps mkKeymapsOption;
  inherit (pkgs) fetchFromGitHub vimUtils;

  tiny-code-action = vimUtils.buildVimPlugin rec {
    name = "tiny-code-action.nvim";
    dependencies = with pkgs.vimPlugins; [ snacks-nvim ];
    src = fetchFromGitHub {
      repo = name;
      owner = "rachartier";
      rev = "0d040ed81f7953118b81cd12681fcdfcac069803";
      hash = "sha256-UF9zeO5Uujdt2MEwy2d2Lhk6JRnEN4vrEvYslv0/zaA=";
    };
  };

  cfg = config.lsp-client;
in
{
  options.lsp-client.keymaps.actions = {
    show = mkKeymapsOption { };
  };

  config = {
    plugins = {
      tiny-inline-diagnostic = {
        enable = true;
        settings.preset = "powerline";
      };
    };

    extraPlugins = [ tiny-code-action ];
    extraPackages = with pkgs; [ difftastic ];
    extraConfigLua = ''
      require("tiny-code-action").setup({
        backend = "difftastic",
        picker = {
          "telescope",
          opts = {
            layout_strategy = "flex"
          }
        }
      })
    '';

    keymaps = mkKeymaps {
      __raw = ''
        function()
          require("tiny-code-action").code_action()
        end
      '';
    } cfg.keymaps.actions.show;
  };
}

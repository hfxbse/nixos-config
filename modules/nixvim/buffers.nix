{
  config,
  lib',
  pkgs,
  ...
}:
let
  inherit (pkgs) fetchFromGitHub vimUtils;
  inherit (lib') mkKeymaps mkKeymapsOption;

  marko-nvim = vimUtils.buildVimPlugin rec {
    name = "marko.nvim";
    dependencies = with pkgs.vimPlugins; [ snacks-nvim ];
    src = fetchFromGitHub {
      repo = name;
      owner = "mohseenrm";
      rev = "7128e7a08fc20fb666c22098a47b1827b500dcd2";
      hash = "sha256-iwOr/uEGQWvbQIJpcgCkIyMlEkcSsQeO8OYOO6Rsp64=";
    };
  };

  cfg = config.buffers;
in
{
  options.buffers.keymaps = {
    buffer.next = mkKeymapsOption { };
    buffer.previous = mkKeymapsOption { };
    buffer.close = mkKeymapsOption { };
    buffer.forceClose = mkKeymapsOption { };
  };

  config = {
    extraPlugins = [ marko-nvim ];
    extraConfigLua = ''
      require("marko").setup()
    '';

    keymaps =
      mkKeymaps "<CMD>bnext<cr>" cfg.keymaps.buffer.next
      ++ mkKeymaps "<CMD>bprevious<cr>" cfg.keymaps.buffer.previous
      ++ mkKeymaps "<CMD>bdelete<cr>" cfg.keymaps.buffer.close
      ++ mkKeymaps "<CMD>bdelete!<cr>" cfg.keymaps.buffer.forceClose;
  };
}

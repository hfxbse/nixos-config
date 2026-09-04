{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkKeymaps mkKeymapsOption;
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
    plugins.bufferline.enable = true;

    keymaps =
      mkKeymaps "<CMD>bnext<cr>" cfg.keymaps.buffer.next
      ++ mkKeymaps "<CMD>bprevious<cr>" cfg.keymaps.buffer.previous
      ++ mkKeymaps "<CMD>bdelete<cr>" cfg.keymaps.buffer.close
      ++ mkKeymaps "<CMD>bdelete!<cr>" cfg.keymaps.buffer.forceClose;
  };
}

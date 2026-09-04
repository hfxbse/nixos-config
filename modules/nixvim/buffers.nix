{ config, lib, ... }:
let
  inherit (lib) types;
  cfg = config.buffers;

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
  options.buffers.keymaps = {
    buffer.next = mkKeymapOption { };
    buffer.previous = mkKeymapOption { };
    buffer.close = mkKeymapOption { };
    buffer.forceClose = mkKeymapOption { };
  };

  config = {
    plugins.bufferline.enable = true;

    keymaps =
      let
        mkKeymaps = action: map (keymap: keymap // { inherit action; });
      in
      mkKeymaps "<CMD>bnext<cr>" cfg.keymaps.buffer.next
      ++ mkKeymaps "<CMD>bprevious<cr>" cfg.keymaps.buffer.previous
      ++ mkKeymaps "<CMD>bdelete<cr>" cfg.keymaps.buffer.close
      ++ mkKeymaps "<CMD>bdelete!<cr>" cfg.keymaps.buffer.forceClose;
  };
}

{config, lib, ... }:
let
  inherit (lib) mkKeymaps mkKeymapsOption;
  cfg = config.git;
in
{
  options.git.keymaps = {
    hunk = {
      next = mkKeymapsOption {};
      preview = mkKeymapsOption {};
      previous = mkKeymapsOption {};
      reset = mkKeymapsOption {};
      toggleStaging = mkKeymapsOption {};
    };

    buffer = {
      reset = mkKeymapsOption {};
      toggleStaging = mkKeymapsOption {};
    };
  };

  config = {
    plugins.gitsigns = {
      enable = true;
      settings = {
        signs_staged_enable = true;
      };
    };

    keymaps =
      mkKeymaps "<CMD>Gitsigns next_hunk<cr>" cfg.keymaps.hunk.next
      ++ mkKeymaps "<CMD>Gitsigns preview_hunk_inline<cr>" cfg.keymaps.hunk.preview
      ++ mkKeymaps "<CMD>Gitsigns prev_hunk<cr>" cfg.keymaps.hunk.previous
      ++ mkKeymaps "<CMD>Gitsigns reset_hunk<cr>" cfg.keymaps.hunk.reset
      ++ mkKeymaps "<CMD>Gitsigns stage_hunk<cr>" cfg.keymaps.hunk.toggleStaging
      ++ mkKeymaps "<CMD>Gitsigns reset_buffer<cr>" cfg.keymaps.buffer.reset
      ++ mkKeymaps "<CMD>Gitsigns stage_buffer<cr>" cfg.keymaps.buffer.toggleStaging;
  };
}

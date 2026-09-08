{
  config,
  lib',
  ...
}:
let
  inherit (lib') mkKeymaps mkKeymapsOption;
  cfg = config.lsp-client;
in
{
  options.lsp-client.keymaps = {
    buffer.format = mkKeymapsOption { };
  };

  config = {
    lsp.inlayHints.enable = true;
    plugins.lspconfig.enable = true;

    keymaps = mkKeymaps { __raw = "vim.lsp.buf.format"; } cfg.keymaps.buffer.format;
  };
}

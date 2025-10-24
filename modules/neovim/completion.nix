{
  pkgs,
  ...
}:
{
  plugins = {
    blink-cmp = {
      enable = true;
      settings = {
        cmdline.enabled = false;
        keymap = {
          preset = "default";
          "<C-j>" = [ "select_and_accept" ];
        };
      };
    };

    lspconfig.enable = true;
    nvim-autopairs.enable = true;
  };

  lsp.servers = {
    clangd.enable = true;
    cssls.enable = true;
    ltex.enable = true;
    nixd = {
      enable = true;
      settings.formatting = {
        command = [ "nixfmt" ];
      };
    };
    ruff.enable = true;
    texlab.enable = true;
    ts_ls.enable = true;
    ty.enable = true;
  };

  extraPackages = with pkgs; [
    nixfmt-rfc-style
  ];
}

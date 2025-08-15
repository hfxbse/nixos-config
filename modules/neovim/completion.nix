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
    ltex.enable = true;
    nixd = {
      enable = true;
      settings.formatting = {
        command = [ "nixfmt" ];
      };
    };
    texlab.enable = true;
  };

  extraPackages = with pkgs; [
    nixfmt-rfc-style
  ];
}

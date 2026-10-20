{ pkgs, ... }:
{
  plugins = {
    blink-cmp = {
      enable = true;
      settings = {
        keymap = {
          preset = "default";
          "<C-j>" = [ "show" "select_and_accept" ];
          "<C-d>" = [ "show_documentation" ];
        };
      };
    };
    endwise.enable = true;
    ts-autotag.enable = true;
  };

  extraPlugins = with pkgs.vimPlugins; [ ultimate-autopair-nvim ];
  extraConfigLua = ''
    require('ultimate-autopair').setup({
    })
  '';
}

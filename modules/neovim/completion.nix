{...}: {
  programs.nixvim = {
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
      nvim-autopairs.enable = true;
    };
  };
}

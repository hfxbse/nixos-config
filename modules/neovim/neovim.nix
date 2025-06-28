{ lib, ... }: {
  imports = [
    ./theme.nix
    ./telescope.nix
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;

    clipboard.providers.wl-copy.enable = lib.mkDefault true;

    opts = {
      number = true;

      clipboard = "unnamedplus";
      wildmode = "list:longest";

      expandtab = true;
      autoindent = true;
      smarttab = true;
      tabstop = 4;
      shiftwidth = 4;
    };

    plugins = {
      nvim-autopairs.enable = true;
      gitsigns.enable = true;
      trim.enable = true;
    };
  };

}

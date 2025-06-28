{...}: {
  imports = [
    ./theme.nix
    ./telescope.nix
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;


    opts = {
      number = true;

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

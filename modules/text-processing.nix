{ pkgs, host, nixvim, ... }: {
  programs.git.enable = true;
  programs.git.config = {
    init.defaultBranch = "main";
    core.editor = "nvim";
    user.name = host.user.description;
  };

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;

    opts = {
      number = true;

      expandtab = true;
      autoindent = true;
      smarttab = true;
      tabstop = 4;
      shiftwidth = 4;
    };

    plugins = {
      vimtex.enable = true;
      nvim-autopairs.enable = true;
      gitsigns.enable = true;
      trim.enable = true;
    };

    extraPlugins = [
      pkgs.vimPlugins.vim-grammarous
    ];
  };
}

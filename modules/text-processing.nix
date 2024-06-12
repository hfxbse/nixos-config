{ host, nixvim, ... }: {
# imports = [ nixvim.nixosModules.nixvim ];

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

    plugins = {
      vimtex.enable = true;
    };
  };
}

{ host, ... }: {
  programs.git.enable = true;
  programs.git.config = {
    init.defaultBranch = "main";
    core.editor = "nvim";
    user.name = host.user.description;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
  };
}

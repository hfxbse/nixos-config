{ config, lib, nixvim, pkgs, ... }: {
  imports = [ ./neovim/neovim.nix ];

  options.user.fullName = lib.mkOption {
    description = "The full name of the user of the machine";
    type = lib.types.str;
  };

  config = {
    programs.git.enable = true;
    programs.git.config = {
      init.defaultBranch = "main";
      core.editor = "nvim";
      user.name = config.user.fullName;
    };
  };
}

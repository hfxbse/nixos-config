{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.user.fullName = lib.mkOption {
    description = "The full name of the user of the machine";
    type = lib.types.str;
  };

  options.text-processing.editor = lib.mkOption {
    description = "Editor derivation";
    type = lib.types.package;
    default = pkgs.nixvim;
  };

  config =
    let
      inherit (config.text-processing) editor;
      editorPath = lib.getExe editor;
    in
    {
      programs.bash.interactiveShellInit = ''
        set -o vi

        HISTSIZE=5000
        HISTFILESIZE=15000
      '';

      programs.git.enable = true;
      programs.git.config = {
        init.defaultBranch = "main";
        core.editor = editorPath;
        user.name = config.user.fullName;
        pull.rebase = true;
      };

      environment = {
        systemPackages = [ editor ];
        variables = lib.genAttrs [ "VISUAL" "EDITOR" ] (name: editorPath);
      };

      fonts.packages = lib.mkIf config.desktop.enable (
        with pkgs;
        [
          nerd-fonts.jetbrains-mono
        ]
      );
    };
}

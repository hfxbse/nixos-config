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

  config =
    let
      editor = (
        pkgs.stdenvNoCC.mkDerivation {
          name = "nixvim";

          dontUnpack = true;
          installPhase = ''
            mkdir -p $out/bin;
            ln -s ${lib.getExe pkgs.nixvim} $out/bin/nvim;
            ln -s $out/bin/nvim $out/bin/vi;
          '';

          meta.mainProgram = "nvim";
        }
      );

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

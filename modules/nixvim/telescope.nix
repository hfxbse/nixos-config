{
  pkgs,
  ...
}:
{
  keymaps = [
    {
      mode = [ "n" ];
      key = "T";
      action = "<cmd>Telescope find_files<cr>";
    }
    {
      mode = [ "n" ];
      key = "sT";
      action = "<cmd>Telescope git_status<cr>";
    }
    {
      mode = [ "n" ];
      key = "gT";
      action = "<cmd>Telescope live_grep<cr>";
    }
    {
      mode = [ "n" ];
      key = "mT";
      action = "<cmd>Telescope buffers<cr>";
    }
  ];

  plugins.telescope = {
    enable = true;
    extensions = {
      live-grep-args.enable = true;
    };

    settings =
      let
        hiddenFiles = [
          "--hidden"
          "--glob"
          "!**/{.git,node_modules}/*"
        ];
      in
      {
        defaults.vimgrep_arguments = [
          "rg"
          "--color=never"
          "--no-heading"
          "--with-filename"
          "--line-number"
          "--column"
        ] ++ hiddenFiles;
        pickers.find_files.find_command = [
          "rg"
          "--files"
        ] ++ hiddenFiles;
      };
  };

  extraPackages = with pkgs; [
    fd
    ripgrep
  ];
}

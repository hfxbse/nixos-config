{
  config,
  lib',
  pkgs,
  ...
}:
let
  inherit (lib') mkKeymaps mkKeymapsOption;
  cfg = config.tests;
in
{
  options.tests.keymaps = {
    log = mkKeymapsOption { };
    next = mkKeymapsOption { };
    overview = mkKeymapsOption { };
    preview = mkKeymapsOption { };
    previous = mkKeymapsOption { };
    run = mkKeymapsOption { };
    runSuite = mkKeymapsOption { };
  };

  config = {

    plugins = {
      neotest = {
        enable = true;
        adapters = {
          gradle = {
            enable = true;
            package = pkgs.vimPlugins.neotest-gradle.overrideAttrs {
              version = "2026-10-19";

              src = pkgs.fetchFromGitHub {
                owner = "hfxbse";
                repo = "neotest-gradle";
                rev = "520b1e7e0295bf6f48747177aca7558011a52036";
                hash = "sha256-eZXaTZ6vo+Wv0kkSLydd11GV7pOLPb00H0NgPRxke/E=";
              };
            };
          };

          jest = {
            enable = true;
            settings = {
              cwd.__raw = ''
                function()
                  local file = vim.api.nvim_buf_get_name(0)
                  local matches = vim.fs.find(
                    {
                      "jest.config.js",
                      "jest.config.ts",
                      "jest.config.cjs",
                      "jest.config.mjs",
                    },
                    {
                      path = vim.fs.dirname(file),
                      stop = vim.fs.dirname(vim.fn.getcwd()),
                      upward = true
                    }
                  )

                  return matches[1]
                    and vim.fs.dirname(matches[1])
                    or vim.fn.getcwd()
                end
              '';
            };
          };
        };
      };
    };

    keymaps =
      mkKeymaps "<CMD>Neotest jump next<cr>" cfg.keymaps.next
      ++ mkKeymaps "<CMD>Neotest jump prev<cr>" cfg.keymaps.previous
      ++ mkKeymaps "<CMD>Neotest output-panel<cr>" cfg.keymaps.log
      ++ mkKeymaps "<CMD>Neotest output<cr>" cfg.keymaps.preview
      ++ mkKeymaps "<CMD>w<cr><CMD>Neotest run<cr>" cfg.keymaps.run
      ++ mkKeymaps "<CMD>w<cr><CMD>Neotest run suite=true<cr>" cfg.keymaps.runSuite
      ++ mkKeymaps "<CMD>Neotest summary<cr>" cfg.keymaps.overview;
  };
}

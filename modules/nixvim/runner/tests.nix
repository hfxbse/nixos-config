{ config, lib', ... }:
let
  inherit (lib') mkKeymaps mkKeymapsOption;
  cfg = config.tests;
in
{
  options.tests.keymaps = {
    next = mkKeymapsOption { };
    overview = mkKeymapsOption { };
    previous = mkKeymapsOption { };
    result = mkKeymapsOption { };
    run = mkKeymapsOption { };
    runSuite = mkKeymapsOption { };
  };

  config = {
    plugins.neotest = {
      enable = true;
      adapters = {
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

    keymaps =
      mkKeymaps "<CMD>Neotest jump next<cr>" cfg.keymaps.next
      ++ mkKeymaps "<CMD>Neotest summary<cr>" cfg.keymaps.overview
      ++ mkKeymaps "<CMD>Neotest jump prev<cr>" cfg.keymaps.previous
      ++ mkKeymaps "<CMD>Neotest output-panel<cr>" cfg.keymaps.result
      ++ mkKeymaps "<CMD>Neotest run<cr>" cfg.keymaps.run
      ++ mkKeymaps "<CMD>Neotest run suite=true<cr>" cfg.keymaps.runSuite;
  };
}

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
      jdtls.enable = false; # Required by Neotest Java adapter

      neotest = {
        enable = true;
        adapters = {
          gradle = {
            enable = true;
            package = pkgs.vimPlugins.neotest-gradle.overrideAttrs (old: {
              patches = (old.patches or [ ]) ++ [ ./neotest-gradle.patch ];
            });
          };

          java = {
            # Different test results than running through Gradle :()
            enable = false;
            settings.junit_jar =
              let
                artifactId = "junit-platform-console-standalone";
                version = "6.0.3";

                junit-platform-console-standalone = pkgs.fetchMavenArtifact {
                  inherit artifactId version;
                  groupId = "org.junit.platform";
                  hash = "sha256-O6DWFQr3khShQR+eovvvhk7vaLaMiaF/ZywLib/506I";
                };
              in
              "${junit-platform-console-standalone}/share/java/${artifactId}-${version}.jar";
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

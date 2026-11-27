{ lib, pkgs, ... }:
{
  env.JDTLS_JVM_ARGS = "-javaagent:${pkgs.lombok}/share/java/lombok.jar";
  lsp.servers = {
    jdtls = {
      enable = true;
      config.before_init.__raw = ''
        function(params, config)
          local style = vim.iter({
            config.root_dir .. "/stylesheet.eclipse.xml",
            config.root_dir .. "/settings/stylesheet.eclipse.xml",
          }):find(function(path)
            return vim.uv.fs_stat(path) ~= nil
          end)

          if not style then
            vim.notify("No eclipse stylesheet found, using default code style.")
            return
          end

          local settings = { java = { format = { enabled = true, settings = { url = style } } } }
          params.initializationOptions = vim.tbl_deep_extend(
            "force",
            params.initializationOptions or {},
            { settings = settings }
          )
          vim.notify("Code stylesheet found at " .. style)
        end
      '';
    };

    kotlin_lsp = {
      enable = true;
      config.cmd = [
        (lib.getExe pkgs.kotlin-lsp)
        "--stdio"
      ];
    };
  };
}

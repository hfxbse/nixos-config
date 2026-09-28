{ lib, pkgs, ... }:
{
  env.JDTLS_JVM_ARGS = "-javaagent:${pkgs.lombok}/share/java/lombok.jar";
  lsp.servers = {
    jdtls.enable = true;
    kotlin_lsp = {
      enable = true;
      config.cmd = [
        (lib.getExe pkgs.kotlin-lsp)
        "--stdio"
      ];
    };
  };
}

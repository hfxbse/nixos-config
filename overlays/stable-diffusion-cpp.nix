{ ... }:
final: prev: {
  stable-diffusion-cpp = prev.stable-diffusion-cpp.overrideAttrs (
    finalAttrs: prevAttrs: rec {
      version = "master-679-f3fd359";

      src = prev.fetchFromGitHub {
        owner = "leejet";
        repo = "stable-diffusion.cpp";
        tag = version;
        hash = "sha256-CeMdXyKup/h6s/n6+jiZLWzTMp0yLUg6ZSp4xmt9sd8=";
        fetchSubmodules = true;
      };

      cmakeFlags = prevAttrs.cmakeFlags ++ [
        "-DSDCPP_BUILD_VERSION=${version}"
      ];

      # Use prepbuild frontend
      patchPhase = ''
        cp -r ${final.sdcpp-webui} examples/server/frontend/dist
      '';

      meta.mainProgram = "sd-server";
    }
  );
}

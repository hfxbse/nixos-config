{ ... }:
final: prev: {
  # See https://wiki.nixos.org/wiki/Lua#Override_a_Lua_package_for_all_available_Lua_interpreters
  luaInterpreters =
    let
      inherit (final.lib.attrsets) filterAttrs mapAttrs;
      isLua = pkg-name: pkg: pkg ? luaversion;

      mkExtendedLuaInterpreters =
        { ... }@args:
        let
          interpreters = prev.luaInterpreters.override args;
        in
        mapAttrs (
          k: v:
          v.override {
            packageOverrides = luafinal: luaprev: {
              image-nvim = luaprev.image-nvim.overrideAttrs (_: rec {
                version = "1.4.0";
                rockspecVersion = "";
                knownRockspec = (
                  builtins.fetchurl {
                    url = "https://raw.githubusercontent.com/3rd/image.nvim/refs/tags/v1.4.0/image.nvim-scm-1.rockspec";
                    sha256 = "1pmay6fl6xm3jk6lkg16vhnf30ikjqamf4wlprmh3jzzgf1wz9q9";
                  }
                );

                src = prev.fetchFromGitHub {
                  owner = "3rd";
                  repo = "image.nvim";
                  tag = "v${version}";
                  sha256 = "sha256-EaDeY8aP41xHTw5epqYjaBqPYs6Z2DABzSaVOnG6D6I=";
                };
              });
            };
          }
        ) (filterAttrs isLua interpreters);
    in
    final.lib.makeOverridable mkExtendedLuaInterpreters { };
}

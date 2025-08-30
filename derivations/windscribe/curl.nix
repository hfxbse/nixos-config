{
  curl,
  fetchurl,
  windscribeSrc,
  ...
}:
let
  src = windscribeSrc;
in
curl.overrideAttrs (
  final: prev: {
    version = "8.9.0";
    src = fetchurl {
      urls = [
        "https://curl.haxx.se/download/curl-${final.version}.tar.xz"
        "https://github.com/curl/curl/releases/download/curl-${
          builtins.replaceStrings [ "." ] [ "_" ] final.version
        }/curl-${final.version}.tar.xz"
      ];
      hash = "sha256-/wmyeRylbSX9XD86SSfc58ip3EGCIAxIfKiJ+6H91BI=";
    };

    patches = [
      "${src}/tools/vcpkg/ports/curl/0005_remove_imp_suffix.patch"
      "${src}/tools/vcpkg/ports/curl/0020-fix-pc-file.patch"
      "${src}/tools/vcpkg/ports/curl/0022-deduplicate-libs.patch"
      "${src}/tools/vcpkg/ports/curl/export-components.patch"
      "${src}/tools/vcpkg/ports/curl/mbedtls-ws2_32.patch"
      "${src}/tools/vcpkg/ports/curl/oqsprovider.patch"
      "${src}/tools/vcpkg/ports/curl/super-large-padding-extension.patch"
    ];
  }
)

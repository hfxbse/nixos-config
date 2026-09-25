{ lib, ... }:
{
  options.applications.language = lib.mkOption {
    description = "The preferred language for applications and websites.";
    default = "en";
    type = lib.types.enum [
      "en"
      "de"
    ];
  };
}

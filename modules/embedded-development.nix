{ host, pkgs, ... }:
{
  services.udev.packages = with pkgs; [
    android-udev-rules
    platformio-core.udev
  ];

  users.groups.dialout.members = [ host.user.name ];  # Non-root access to serial ports
  users.groups.adbuser.members = [ host.user.name ];
}

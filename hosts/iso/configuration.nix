{ lib, pkgs, modulesPath, wifi, ... }: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  console.keyMap = "de";

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  users.users.nixos.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZ+E9Z/v59BvCIy1araM9vc4NBPSCZn4KHNOCh6z1WmHiptIXmXh1yDXEXw3VmNC8wqzXkGjgDP4fph+W9yzOM3XPfndMa0kyYdC15qk8vP9qliYye0dB49z5zdo0xvkJR9/Z1amQNzH+RitwpSlwDZeQIDAoWYqWCkzQhyYY96NzbjLCoJ8QWXouPfMKPQ6sDqtNN2WUd5w8ISctj/892aEPOGovryjeJy3fB0d116Oe1R1FsAfMqw4o2meDjoiaoHGdN0E9cWWOclipTZInuGZiSprLT86hk8t5YsYQv/UDlbqh/2IcnKrD4dUpNqkCPxHH/ICEFzmaolcE0VyrV nixos"
  ];

  networking.wireless = {
    enable = true;
    userControlled.enable = lib.mkForce false;

    networks."${wifi.ssid}" = {
      psk = wifi.psk;
    };
  };

  services.logind.lidSwitch = "ignore";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.hostPlatform = "x86_64-linux";
}

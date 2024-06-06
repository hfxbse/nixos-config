{ host, ... }: {
  users.groups.wootility.members = [ host.user.name ];
  services.udev.extraRules = builtins.readFile ./wootility-udev.rules;
}

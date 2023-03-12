{}:
rec {
  imports = [
    ./hardware-configuration.nix
    ./nvidia.nix
  ];

  user = {
      name = "fhs";
      description = "Fabian Haas";
  };
  
  name = "nt-${user.name}";
}

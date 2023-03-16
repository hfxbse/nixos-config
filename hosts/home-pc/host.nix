{}:
rec {
  imports = [
    ./hardware-configuration.nix
  ];

  user = {
      name = "fxbse";
      description = "Fabian Haas";
  };
  
  name = "ice-cube";
}

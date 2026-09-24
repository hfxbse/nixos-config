let
  user = "fabian.haas";
in
{
  users.users.${user}.home = "/Users/${user}";
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users."fabian.haas" = {
      programs.zsh.enable = true;
      # DO NOT CHANGE AFTER INSTALLING THE SYSTEM
      home.stateVersion = "26.11"; # Did you read the comment?
    };
  };

  # DO NOT CHANGE AFTER INSTALLING THE SYSTEM
  system.stateVersion = 6; # Did you read the comment?
}

let
  username = "fabian.haas";
in
{
  single-user = { inherit username; };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} = {
      applications = {
        browser.enable = true;
        multimedia.enable = true;
      };

      programs.zsh.enable = true;

      # DO NOT CHANGE AFTER INSTALLING THE SYSTEM
      home.stateVersion = "26.11"; # Did you read the comment?
    };
  };

  # DO NOT CHANGE AFTER INSTALLING THE SYSTEM
  system.stateVersion = 6; # Did you read the comment?
}

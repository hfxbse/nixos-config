rec {
  user.name = "fabian.haas";
  nixpkgs.hostPlatform = "aarch64-darwin";


  # DO NOT CHANGE AFTER INSTALLING THE SYSTEM
  system.stateVersion = 6; # Did you read the comment?
  home-manager.users.${user.name} = {
    browser.enable = true;
    home.stateVersion = "26.11";
  };
}

rec {
  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
  };

  user.name = "fabian.haas";
  multimedia.enable = true;
  home-manager.users.${user.name} = {
    browser.enable = true;

    # DO NOT CHANGE AFTER INSTALLING THE SYSTEM
    home.stateVersion = "26.11"; # Did you read the comment?
  };

  # DO NOT CHANGE AFTER INSTALLING THE SYSTEM
  system.stateVersion = 6; # Did you read the comment?
}

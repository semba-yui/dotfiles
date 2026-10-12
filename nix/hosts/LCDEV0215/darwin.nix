{ username, ... }:

{
  imports = [
    ../../modules/darwin/fish.nix
    ./homebrew.nix
  ];

  system.stateVersion = 6;

  users.users.${username}.uid = 501;
}

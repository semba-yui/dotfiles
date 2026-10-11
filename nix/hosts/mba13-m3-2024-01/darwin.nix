{
  homeDirectory,
  username,
  ...
}:

{
  networking.hostName = "mba13-m3-2024-01";

  nixpkgs.hostPlatform = "aarch64-darwin";

  system = {
    primaryUser = username;
    stateVersion = 6;
  };

  users.users.${username} = {
    home = homeDirectory;
    uid = 501;
  };
}

{
  homeDirectory,
  username,
  ...
}:

{
  networking.hostName = "SembaYui";

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

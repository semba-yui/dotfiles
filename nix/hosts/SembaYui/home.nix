{
  homeDirectory,
  username,
  ...
}:

{
  imports = [ ../../modules/home ];

  home = {
    inherit homeDirectory username;
    stateVersion = "26.05";
  };
}

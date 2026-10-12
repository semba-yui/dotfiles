{
  homeDirectory,
  hostname,
  username,
  ...
}:

# どの Mac でも、この dotfiles を保守できることと、同じ操作感で使えることに必要なものだけを置く。
{
  imports = [
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/macos
    ../../modules/darwin/nix.nix
    ../../modules/darwin/nixpkgs.nix
    ../../modules/darwin/security.nix
  ];

  networking.hostName = hostname;

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = username;

  users.users.${username}.home = homeDirectory;
}

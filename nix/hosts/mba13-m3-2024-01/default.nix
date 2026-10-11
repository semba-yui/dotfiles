{ inputs }:

let
  homeDirectory = "/Users/semba";
  username = "semba";
in
inputs.nix-darwin.lib.darwinSystem {
  specialArgs = {
    inherit homeDirectory inputs username;
  };

  modules = [
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew

    ../../modules/darwin/nix.nix
    ../../modules/darwin/nixpkgs.nix

    ../../modules/darwin/security.nix
    ../../modules/darwin/macos/keyboard.nix
    ../../modules/darwin/macos/text-input.nix
    ../../modules/darwin/macos/finder.nix
    ../../modules/darwin/macos/trackpad.nix

    ./homebrew.nix
    ./darwin.nix

    {
      home-manager = {
        extraSpecialArgs = {
          inherit homeDirectory inputs username;
        };
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${username} = import ./home.nix;
      };
    }
  ];
}

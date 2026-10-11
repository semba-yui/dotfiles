{ hostname, inputs }:

let
  homeDirectory = "/Users/semba";
  username = "semba";
in
inputs.nix-darwin.lib.darwinSystem {
  specialArgs = {
    inherit
      homeDirectory
      hostname
      inputs
      username
      ;
  };

  modules = [
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew

    ../../modules/darwin/fish.nix
    ../../modules/darwin/macos
    ../../modules/darwin/nix.nix
    ../../modules/darwin/nixpkgs.nix
    ../../modules/darwin/security.nix

    ./homebrew.nix
    ./darwin.nix

    {
      home-manager = {
        extraSpecialArgs = {
          inherit
            homeDirectory
            hostname
            inputs
            username
            ;
        };
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${username} = import ./home.nix;
      };
    }
  ];
}

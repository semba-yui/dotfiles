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
    ../../modules/darwin
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

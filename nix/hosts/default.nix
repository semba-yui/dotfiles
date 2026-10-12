{ inputs }:

let
  # 所有する Mac はすべて同じアカウント名で運用する。端末ごとに変える必要が出たらホスト側へ移す。
  username = "semba";
  homeDirectory = "/Users/${username}";

  # ホストは nix/hosts/<LocalHostName>/ の darwin.nix と home.nix で、共通セットへの差分だけを書く。
  mkHost =
    hostname:
    let
      specialArgs = {
        inherit
          homeDirectory
          hostname
          inputs
          username
          ;
      };
    in
    inputs.nix-darwin.lib.darwinSystem {
      inherit specialArgs;
      modules = [
        inputs.home-manager.darwinModules.home-manager
        ../profiles/base/darwin.nix
        ./${hostname}/darwin.nix
        {
          home-manager = {
            extraSpecialArgs = specialArgs;
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username}.imports = [
              ../profiles/base/home.nix
              ./${hostname}/home.nix
            ];
          };
        }
      ];
    };
in
# ディレクトリを置くだけで登録され、ディレクトリ名がそのままホスト名になる。
builtins.mapAttrs (hostname: _: mkHost hostname) (
  inputs.nixpkgs.lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./.)
)

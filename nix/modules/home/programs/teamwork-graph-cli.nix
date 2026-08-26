{ lib, pkgs, ... }:

let
  teamworkGraphCliBinary = pkgs.callPackage ../../../packages/teamwork-graph-cli.nix { };
  teamworkGraphCliLauncher = pkgs.writeShellApplication {
    name = "twg";
    text = ''
      export DO_NOT_TRACK=1
      # TWG に認証情報の永続化を委ね、owner-only の auth.conf を使う公式デフォルトを上書きしない。
      exec ${lib.getExe teamworkGraphCliBinary} "$@"
    '';
  };
in
{
  home.packages = [ teamworkGraphCliLauncher ];
}

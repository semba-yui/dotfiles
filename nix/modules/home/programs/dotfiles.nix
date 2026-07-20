{
  config,
  lib,
  pkgs,
  ...
}:

let
  flakeDirectory = config.programs.nh.darwinFlake;
  repositoryDirectory = "${flakeDirectory}/..";

  dotfiles = pkgs.writeShellApplication {
    name = "dotfiles";

    runtimeInputs = [
      pkgs.git
      pkgs.just
      pkgs.nh
      pkgs.nix
      pkgs.oxfmt
    ];

    text = ''
      exec just --justfile ${lib.escapeShellArg "${repositoryDirectory}/justfile"} "$@"
    '';
  };
in
{
  # リポジトリの場所を利用者に意識させず、すべての保守タスクへ同じ入口からアクセスできるようにする。
  home.packages = [ dotfiles ];
}

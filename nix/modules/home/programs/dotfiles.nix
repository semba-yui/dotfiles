{
  config,
  lib,
  pkgs,
  ...
}:

let
  flakeDirectory = config.programs.nh.darwinFlake;

  dotfiles = pkgs.writeShellApplication {
    name = "dotfiles";

    runtimeInputs = [
      pkgs.git
      pkgs.just
      pkgs.nh
      pkgs.nix
    ];

    text = ''
      exec just --justfile ${lib.escapeShellArg "${flakeDirectory}/justfile"} "$@"
    '';
  };
in
{
  # リポジトリの場所を利用者に意識させず、すべての保守タスクへ同じ入口からアクセスできるようにする。
  home.packages = [ dotfiles ];
}

{ pkgs, ... }:

{
  # Home Manager のユーザー設定とは別に、fish を macOS のログインシェルとして利用可能にする。
  environment.shells = [ pkgs.fish ];

  programs.fish.enable = true;
}

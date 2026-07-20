{ config, ... }:
{
  programs.nh = {
    enable = true;

    # 端末ごとに異なるホームディレクトリから導出し、どこからでも対象Flakeを操作できるようにする。
    darwinFlake = "${config.home.homeDirectory}/ghq/github.com/semba-yui/dotfiles/nix";
  };
}

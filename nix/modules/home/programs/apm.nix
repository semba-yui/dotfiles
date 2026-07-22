{ config, pkgs, ... }:

let
  repositoryDirectory = builtins.dirOf config.programs.nh.darwinFlake;
in
{
  home.packages = [ pkgs.apm-cli ];

  # APM自身がmanifestとlockを更新するため、Nix storeへコピーせず作業ツリーを正本にする。
  # ディレクトリ単位でリンクし、APMのatomic replaceで個別ファイルのリンクが壊れるのを避ける。
  home.file.".apm" = {
    source = config.lib.file.mkOutOfStoreSymlink "${repositoryDirectory}/apm";
    force = true;
  };
}

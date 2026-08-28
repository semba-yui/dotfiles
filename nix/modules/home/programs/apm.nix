{ config, pkgs, ... }:

let
  apmCliWithWebsocketsRuntimeDependency = pkgs.callPackage ../../../packages/apm-cli.nix { };
  repositoryDirectory = builtins.dirOf config.programs.nh.darwinFlake;
in
{
  home.packages = [ apmCliWithWebsocketsRuntimeDependency ];

  # APM自身がmanifestとlockを更新するため、Nix storeへコピーせず作業ツリーを正本にする。
  # ディレクトリ単位でリンクし、APMのatomic replaceで個別ファイルのリンクが壊れるのを避ける。
  home.file.".apm" = {
    source = config.lib.file.mkOutOfStoreSymlink "${repositoryDirectory}/apm";
    force = true;
  };
}

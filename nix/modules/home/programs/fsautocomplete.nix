{ pkgs, ... }:

let
  # nixpkgs の fsautocomplete は `which dotnet` の realpath から DOTNET_ROOT を決める。
  # PATH 先頭の mise shim は mise 本体へのシンボリックリンクなので DOTNET_ROOT が mise の bin を指し、
  # 起動直後にクラッシュする。Nix の SDK を PATH 先頭に固定して回避する。
  # SDK を home.packages に入れないのは、PATH 上で mise shim に隠れて使われず混乱を招くため。
  fsautocompleteWithNixDotnet = pkgs.writeShellScriptBin "fsautocomplete" ''
    export PATH=${pkgs.dotnet-sdk_10}/bin:$PATH
    exec ${pkgs.fsautocomplete}/bin/fsautocomplete "$@"
  '';
in
{
  home.packages = [ fsautocompleteWithNixDotnet ];
}

{ pkgs, ... }:

let
  apmCliWithWebsocketsRuntimeDependency = pkgs.callPackage ../../../packages/apm-cli.nix { };
in
{
  # CLI だけ入れる。グローバル scope（~/.apm）は使わない。apm は ~/.apm が symlink だと
  # skill を配置できず、実ディレクトリにすると lock が flake.lock と 2 本になるため、
  # 端末共通の skill は agent-skills.nix で扱い、apm はプロジェクト scope の用途に限る。
  home.packages = [ apmCliWithWebsocketsRuntimeDependency ];
}

{ config, pkgs, ... }:

let
  repositoryDirectory = builtins.dirOf config.programs.nh.darwinFlake;
in
{
  home.file.".claude/scripts/statusline.sh" = {
    source = config.lib.file.mkOutOfStoreSymlink "${repositoryDirectory}/claude/.claude/scripts/statusline.sh";
    force = true;
  };

  programs.claude-code = {
    enable = true;

    # nixpkgs の取り込みは上流リリースから数日遅れる。日次で更新が出るツールのため、
    # packages/claude-code-release.json で上流リリースを直接固定した派生を使う。
    package = pkgs.callPackage ../../../packages/claude-code.nix { };

    # ユーザー指示は動的状態ではないため、Home Managerの標準オプションで配置する。
    context = ../../../../claude/.claude/CLAUDE.md;
  };
}

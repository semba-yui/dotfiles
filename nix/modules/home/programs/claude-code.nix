{ config, ... }:

let
  repositoryDirectory = builtins.dirOf config.programs.nh.darwinFlake;
in
{
  home.file.".claude/scripts/statusline.sh" = {
    source = config.lib.file.mkOutOfStoreSymlink "${repositoryDirectory}/claude/.claude/scripts/statusline.sh";
    force = true;
  };

  # 本体とランチャーは公式の自動更新に任せ、共有する指示だけを配置する。
  home.file.".claude/CLAUDE.md".source = ../../../../claude/.claude/CLAUDE.md;
}

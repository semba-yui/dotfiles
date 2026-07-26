{ config, ... }:

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

    # ユーザー指示は動的状態ではないため、Home Managerの標準オプションで配置する。
    context = ../../../../claude/.claude/CLAUDE.md;
  };
}

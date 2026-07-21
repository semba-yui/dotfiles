{ config, ... }:

let
  repositoryDirectory = builtins.dirOf config.programs.nh.darwinFlake;
in
{
  # CLIから変更した内容もGit差分にするため、Nix storeへコピーせずdotfilesの正本へ直接つなぐ。
  # 認証や履歴も混在する ~/.claude 全体は対象にせず、宣言的に共有したいファイルだけをリンクする。
  home.file = {
    ".claude/settings.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${repositoryDirectory}/claude/.claude/settings.json";
      force = true;
    };

    ".claude/scripts/statusline.sh" = {
      source = config.lib.file.mkOutOfStoreSymlink "${repositoryDirectory}/claude/.claude/scripts/statusline.sh";
      force = true;
    };
  };

  programs.claude-code = {
    enable = true;

    # ユーザー指示は動的状態ではないため、Home Managerの標準オプションで配置する。
    context = ../../../../claude/.claude/CLAUDE.md;
  };
}

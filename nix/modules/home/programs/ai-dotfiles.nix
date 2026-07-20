{
  config,
  ...
}:

let
  repositoryDirectory = builtins.dirOf config.programs.nh.darwinFlake;
  linkFromRepository = path: config.lib.file.mkOutOfStoreSymlink "${repositoryDirectory}/${path}";
in
{
  # CLIから変更した内容もGit差分にするため、Nix storeへコピーせずdotfilesの正本へ直接つなぐ。
  # 認証や履歴も混在する ~/.claude 全体は対象にせず、宣言的に共有したいファイルだけをリンクする。
  home.file.".claude/settings.json" = {
    source = linkFromRepository "claude/.claude/settings.json";
    force = true;
  };
}

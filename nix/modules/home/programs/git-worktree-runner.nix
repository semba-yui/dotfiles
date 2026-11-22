{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  # nixpkgs 未収載のため、flake input のソースから自前でパッケージ化する。
  gitWorktreeRunner = pkgs.callPackage ../../../packages/git-worktree-runner.nix {
    src = inputs.git-worktree-runner;
  };

  # 起動ごとに `git gtr init fish` を実行しない。gtr は全サブコマンドの前に Git 設定の
  # 安全検査を走らせ、Home Manager の symlink 構成ではこれが起動を秒単位で遅らせる。
  # 出力はホストや git 設定に依存しないので、ビルド時に一度だけ生成する。
  # ビルド環境の ls は GNU 版で -e を持たず ACL 検査が失敗するため、BSD ls を先頭に置く。
  gitWorktreeRunnerFishIntegration = pkgs.runCommand "git-gtr-init.fish" { } ''
    export PATH=${lib.makeBinPath [ pkgs.darwin.file_cmds ]}:$PATH
    ${lib.getExe gitWorktreeRunner} init fish > $out
  '';
in
{
  home.packages = [ gitWorktreeRunner ];

  # Home Manager の fzf 統合(mkOrder 200)より後に読み込み、`gtr cd` の fzf picker を確実に使えるようにする。
  programs.fish.interactiveShellInit = ''
    source ${gitWorktreeRunnerFishIntegration}
  '';
}

{
  config,
  lib,
  pkgs,
  ...
}:

let
  repositoryDirectory = builtins.dirOf config.programs.nh.darwinFlake;

  # リポジトリ直下 fish/ の実ファイルを ~/.config/fish/ の同じ相対パスへリンクする。
  # シェル上で編集した内容をそのまま Git 差分にするため、Nix store コピーにしない。
  # conf.d/ や functions/ は Home Manager も生成物(plugin-hydro.fish 等)を置くため、
  # ディレクトリごとではなくファイル単位でリンクして共存させる。
  fishSourceFiles = [
    "conf.d/fzf-widgets.fish"
    "functions/fzf_ghq_repos.fish"
    "functions/fzf_git_branches.fish"
    "functions/fzf_zoxide_jump.fish"
    "functions/gwn.fish"
    "functions/gwd.fish"
    "functions/fkill.fish"
  ];
in
{
  # fish は programs.man.generateCaches を自動で有効化するが、macOS + stateVersion
  # 26.05 では programs.man.package が null（man はシステム側を使う）のため無効。
  # 何も起きない設定なので明示的に off にして警告を消す。
  programs.man.generateCaches = false;

  xdg.configFile = lib.listToAttrs (
    map (
      relativePath:
      lib.nameValuePair "fish/${relativePath}" {
        source = config.lib.file.mkOutOfStoreSymlink "${repositoryDirectory}/fish/${relativePath}";
        force = true;
      }
    ) fishSourceFiles
  );

  programs.fish = {
    enable = true;

    # trueだとman pageからfish補完を生成しようとする。
    generateCompletions = false;

    # gtr の wrapper 関数(cd / new --cd)と補完を有効化する。
    # conf.d ではなく config.fish で source する理由: Home Manager の fzf 統合
    # (mkOrder 200)より後に読み込み、`gtr cd` の fzf picker を確実に使えるようにする。
    # 初回 switch 中など gtr 未導入のシェルでも起動を壊さないよう存在確認でガードする。
    interactiveShellInit = ''
      if command -q git-gtr
          git gtr init fish | source
      end
    '';

    # pluginの取得元とバージョンをnixpkgsへ統一し、Fish内に別のpackage managerを持ち込まない。
    plugins = [
      {
        name = "hydro";
        src = pkgs.fishPlugins.hydro.src;
      }
    ];

    preferAbbrs = true;
  };
}

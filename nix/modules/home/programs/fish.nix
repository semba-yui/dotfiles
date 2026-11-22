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
    "functions/fzf_command_palette.fish"
    "functions/fzf_create_worktree_from_base_branch.fish"
    "functions/fzf_ghq_repos.fish"
    "functions/fzf_git_branches.fish"
    "functions/fzf_zoxide_jump.fish"
    "functions/gwn.fish"
    "functions/gwd.fish"
    "functions/gwo.fish"
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

    # pluginの取得元とバージョンをnixpkgsへ統一し、Fish内に別のpackage managerを持ち込まない。
    plugins = [
      {
        name = "hydro";
        src = pkgs.fishPlugins.hydro.src;
      }
    ];

    preferAbbrs = true;

    # ls/ll/la/lt/lla は Home Manager の eza モジュールが mkDefault で生成する。
    # 同名キーを再定義して上書きする(alias を足しても abbr が先に展開して効かない)。
    # --icons は値省略時に直後の位置引数を WHEN として食うため =auto を明示する。
    shellAbbrs = {
      # zoxide の --cmd cd は zsh と bash の cd も置き換え、Claude Code の Bash ツール（zsh）を壊すため、
      # fish の対話シェルだけで展開する abbr にする。z は実在するパスなら通常の cd と同じに動く。
      cd = "z";
      la = "eza -a --icons=auto --group-directories-first";
      ll = "eza -la --icons=auto --group-directories-first --git";
      lla = "eza -la --icons=auto --group-directories-first";
      ls = "eza --icons=auto --group-directories-first";
      lt = "eza --tree --level=2 --icons=auto";
    };
  };
}

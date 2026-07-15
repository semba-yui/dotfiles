{ ... }:

{
  # fish は programs.man.generateCaches を自動で有効化するが、macOS + stateVersion
  # 26.05 では programs.man.package が null（man はシステム側を使う）のため無効。
  # 何も起きない設定なので明示的に off にして警告を消す。
  programs.man.generateCaches = false;

  programs.fish = {
    enable = true;

    # trueだとman pageからfish補完を生成しようとする。
    generateCompletions = false;

    preferAbbrs = true;
  };
}

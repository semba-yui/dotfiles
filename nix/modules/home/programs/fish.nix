{ pkgs, ... }:

{
  # fish は programs.man.generateCaches を自動で有効化するが、macOS + stateVersion
  # 26.05 では programs.man.package が null（man はシステム側を使う）のため無効。
  # 何も起きない設定なので明示的に off にして警告を消す。
  programs.man.generateCaches = false;

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
  };
}

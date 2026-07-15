{
  # エディタやチャットで入力内容が暗黙に変わらないよう、macOS 共通の自動補正を無効化する。
  system.defaults.NSGlobalDomain = {
    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticPeriodSubstitutionEnabled = false;
  };
}

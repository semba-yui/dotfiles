{
  # エディタやチャットで入力内容が暗黙に変わらないよう、macOS 共通の自動補正を無効化する。
  system.defaults.NSGlobalDomain = {
    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticDashSubstitutionEnabled = false;
    NSAutomaticInlinePredictionEnabled = false;
    NSAutomaticPeriodSubstitutionEnabled = false;
    NSAutomaticQuoteSubstitutionEnabled = false;
    NSAutomaticSpellingCorrectionEnabled = false;
  };

  # 同じ理由で、macOS 標準の日本語入力も Space を押すまで確定前の文字を変えないようにする。
  # 推測候補は窓に候補を出すだけで入力を書き換えないため、既定のまま残す。
  system.defaults.CustomUserPreferences."com.apple.inputmethod.Kotoeri" = {
    JIMPrefAutocorrectionKey = false;
    JIMPrefFullWidthNumeralCharactersKey = false;
    JIMPrefLiveConversionKey = false;
  };
}

{
  system.defaults.controlcenter = {
    # 残量低下をアイコンの見た目だけで判断せず、充電の必要性を数値で把握できるようにする。
    BatteryShowPercentage = true;

    # 必要時にコントロールセンターから開ける項目は隠し、メニューバーの領域を確保する。
    AirDrop = false;
    Bluetooth = false;
    Display = false;
    FocusModes = false;
    NowPlaying = false;
    Sound = false;
  };

  system.defaults.menuExtraClock = {
    # 24時間表記に統一し、午前・午後の読み違いとAM/PM表示の重複を避ける。
    Show24Hour = true;
    ShowAMPM = false;

    # 日付は領域に余裕がある場合だけ表示し、曜日は予定を判断するため常に表示する。
    ShowDate = 0;
    ShowDayOfWeek = true;

    # 秒単位の常時更新は通常の業務で不要なため、情報量と視覚的な動きを抑える。
    ShowSeconds = false;
  };
}

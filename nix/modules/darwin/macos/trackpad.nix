{
  # 端末を替えても同じポインター操作を再現できるよう、意図した有効・無効を明示する。
  system.defaults.trackpad = {
    # 指が触れただけでクリックになる誤操作を避け、押し込み操作をクリックとして扱う。
    Clicking = false;

    # 2本指による副ボタンクリックは、クリック位置に依存せず操作できるため有効にする。
    TrackpadRightClick = true;

    # 3本指ジェスチャーとの混同を避け、ドラッグは押し込み操作に限定する。
    TrackpadThreeFingerDrag = false;
  };

  system.defaults.NSGlobalDomain = {
    # マウス利用時の操作感を優先し、ホイールを動かした方向へ画面をスクロールする。
    "com.apple.swipescrolldirection" = false;

    # ポインターを十分速く動かしつつ、最大値にして細かな操作性を失うことは避ける。
    "com.apple.trackpad.scaling" = 2.0;
  };
}

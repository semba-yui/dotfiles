{
  system.defaults.NSGlobalDomain = {
    # 長押し時のアクセント文字メニューより、カーソル移動や文字の連続入力を優先する。
    ApplePressAndHoldEnabled = false;

    # 誤入力を抑えつつ、長押しから連続入力へ移るまでの待ち時間を短くする。
    InitialKeyRepeat = 15;

    # 最速値では過剰入力が起きやすいため、十分に速く制御しやすい間隔を採用する。
    KeyRepeat = 2;

    # 開発ツールのショートカットで Fn キーを併用せず、F1、F2 などを直接入力できるようにする。
    "com.apple.keyboard.fnState" = true;
  };
}

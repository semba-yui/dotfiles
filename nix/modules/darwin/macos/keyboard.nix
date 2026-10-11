{ config, ... }:

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

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  # hidutil の割り当ては再起動で消え、nix-darwin は switch 時にしか設定しないため、ログイン時に再適用する。
  launchd.user.agents.caps-lock-control.serviceConfig = {
    ProgramArguments = [
      "/usr/bin/hidutil"
      "property"
      "--set"
      (builtins.toJSON { UserKeyMapping = config.system.keyboard.userKeyMapping; })
    ];
    RunAtLoad = true;
  };
}

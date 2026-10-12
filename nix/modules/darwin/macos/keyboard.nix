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

  # ⌘Space を Raycast へ譲るため、Spotlight を開くショートカット（ID 64）だけを無効にする。
  # system.defaults で宣言すると AppleSymbolicHotKeys 全体が置き換わり、他のショートカットの変更を失うため、
  # この項目だけを -dict-add で書き換える。反映には再ログインが必要。
  system.activationScripts.postActivation.text = ''
    launchctl asuser "$(id -u -- ${config.system.primaryUser})" sudo --user=${config.system.primaryUser} -- \
      defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
      '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>'
  '';

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

{ ... }:

let
  remap = from: to: {
    type = "basic";
    from = {
      key_code = from;
      modifiers.optional = [ "any" ];
    };
    to = [ { key_code = to; } ];
  };

  commandTap = key: ime: {
    type = "basic";
    from = {
      key_code = key;
      modifiers.optional = [ "any" ];
    };
    to = [
      {
        key_code = key;
        lazy = true;
      }
    ];
    to_if_alone = [ { key_code = ime; } ];
  };
in
{
  # ルールの有効化まで宣言するため、Karabiner の設定ファイルごと管理する。GUI からの変更は保存できなくなる。
  # 初回は Karabiner が生成した既定の設定を置き換えるため force を指定する。
  xdg.configFile."karabiner/karabiner.json" = {
    force = true;
    text = builtins.toJSON {
      profiles = [
        {
          name = "Default profile";
          selected = true;
          virtual_hid_keyboard.keyboard_type_v2 = "ansi";

          # Karabiner は macOS の修飾キー設定を無視するため、Caps Lock の割り当てもここで行う。
          complex_modifications.rules = [
            {
              description = "US keyboard: Command IME switching and modifier remapping";

              manipulators = [
                (commandTap "left_command" "japanese_eisuu")
                (commandTap "right_command" "japanese_kana")
                (remap "caps_lock" "left_control")
                (remap "left_control" "left_command")
              ];
            }
          ];
        }
      ];
    };
  };
}

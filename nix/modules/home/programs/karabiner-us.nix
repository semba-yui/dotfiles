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
  xdg.configFile."karabiner/assets/complex_modifications/us-ansi.json".text = builtins.toJSON {
    title = "US ANSI keyboard";

    rules = [
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
  };
}

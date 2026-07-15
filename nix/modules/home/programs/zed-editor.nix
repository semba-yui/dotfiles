{ pkgs, ... }:
{
  home.sessionVariables = {
    # ターミナルから起動した処理が、編集終了まで正しく待機できるようにする。
    EDITOR = "zeditor --wait";
    VISUAL = "zeditor --wait";
  };

  programs.zed-editor = {
    enable = true;
    package = pkgs.zed-editor;

    userSettings = {
      vim_mode = false;
      base_keymap = "VSCode";
      load_direnv = "shell_hook";
      hour_format = "hour24";

      ui_font_size = 14;
      buffer_font_size = 14;
    };
  };
}

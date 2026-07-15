{ pkgs, ... }:
{
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

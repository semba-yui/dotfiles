{ config, pkgs, ... }:

{
  home.username = "semba";
  home.homeDirectory = "/Users/semba";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    git
  ];

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

    extraPackages = with pkgs; [
      nixd
      nil
      nixfmt-rfc-style
    ];
  };
}

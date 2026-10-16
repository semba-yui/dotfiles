_: {
  home.sessionVariables = {
    # ターミナルから起動した処理が、編集終了まで正しく待機できるようにする。
    EDITOR = "zed --wait";
    VISUAL = "zed --wait";
  };

  programs.zed-editor = {
    enable = true;
    # 本体はホストの homebrew.nix の cask で入れ、ここでは設定だけを持つ。nixpkgs の Zed は
    # チャンネルの更新を止める対象ではないため、darwin でビルドに失敗した版がキャッシュなしで
    # 降りてきて、ローカルで 1 時間近いビルドになることがある。版は flake.lock で固定されず、
    # Zed 自身の自動更新に任せる。CLI は nixpkgs の zeditor ではなく cask の zed になる。
    package = null;

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

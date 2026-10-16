{
  homebrew = {
    casks = [
      "chatgpt"
      "claude"
      "discord"
      "drawio"
      "figma"
      "fork"
      "google-chrome"
      "google-japanese-ime"
      "jetbrains-toolbox"
      "karabiner-elements"
      "microsoft-excel"
      "microsoft-powerpoint"
      "microsoft-teams"
      "microsoft-word"
      "orbstack"
      "raycast"
      "slack"
      "terminal-browser"
      "zed"
      "zoom"
    ];

    # Amphetamine は App Store だけで配布され、Bitwarden は Safari 拡張に対応する App Store 版を使う。
    # 導入には App Store へのサインインが必要になる。
    masApps = {
      Amphetamine = 937984704;
      Bitwarden = 1352778147;
    };

    onActivation = {
      cleanup = "uninstall";
      upgrade = true;
    };
  };
}

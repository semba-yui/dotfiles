{ username, ... }:

{
  nix-homebrew = {
    enable = true;
    enableRosetta = false;
    user = username;
    mutableTaps = false;
  };

  homebrew = {
    enable = true;

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
      "zoom"
    ];

    # Amphetamine は App Store だけで配布され、Bitwarden は Safari 拡張に対応する App Store 版を使う。
    # 導入には App Store へのサインインが必要になる。
    masApps = {
      Amphetamine = 937984704;
      Bitwarden = 1352778147;
    };

    onActivation = {
      autoUpdate = false;
      # 大きなアプリの取得中も止まって見えないよう、段階ごとの進捗を表示する。
      extraFlags = [ "--verbose" ];
      upgrade = false;
      cleanup = "none";
    };
  };
}

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
      "discord"
      "figma"
      "google-chrome"
      "google-japanese-ime"
      "karabiner-elements"
      "orbstack"
      "raycast"
      "slack"
    ];

    # App Store 版は Safari 拡張にも対応するため、会社Macと同じく mas で導入する。
    # 導入には App Store へのサインインが必要になる。
    masApps.Bitwarden = 1352778147;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };
  };
}

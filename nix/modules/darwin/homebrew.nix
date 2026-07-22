{
  inputs,
  username,
  ...
}:

{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  nix-homebrew = {
    enable = true;
    enableRosetta = false;
    mutableTaps = false;
    user = username;

    extraEnv = {
      # Homebrew は macOS アプリ用に限定し、CLI や依存ライブラリは Nix で管理する。
      HOMEBREW_FORBIDDEN_TAPS = "homebrew/core";
      HOMEBREW_NO_ANALYTICS = "1";
    };
  };

  homebrew = {
    enable = true;

    masApps = {
      Bitwarden = 1352778147;
      Keynote = 409183694;
      Numbers = 409203825;
      Pages = 409201541;
    };

    casks = [
      "chatgpt"
      "claude"
      "cleanshot"
      "discord"
      "drawio"
      "fork"
      "google-chrome"
      "google-japanese-ime"
      "jetbrains-toolbox"
      "microsoft-teams"
      "orbstack"
      "raycast"
      "slack"
      "zoom"
    ];

    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = true;
    };
  };
}

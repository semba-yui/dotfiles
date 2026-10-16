{ inputs, ... }:

{
  nix-homebrew = {
    taps = {
      "k1LoW/homebrew-tap" = inputs.homebrew-k1low-tap;
    };

    trust.formulae = [ "k1LoW/tap/mo" ];
  };

  homebrew = {
    brews = [ "k1LoW/tap/mo" ];

    masApps = {
      Amphetamine = 937984704;
      Bitwarden = 1352778147;
    };

    casks = [
      "adobe-acrobat-pro"
      "adobe-creative-cloud"
      "chatgpt"
      "claude"
      "cleanshot"
      "discord"
      "drawio"
      "figma"
      "fork"
      "github-copilot-app"
      "google-chrome"
      "google-japanese-ime"
      "jetbrains-toolbox"
      "logi-options+"
      "microsoft-excel"
      "microsoft-powerpoint"
      "microsoft-teams"
      "microsoft-word"
      "orbstack"
      "raycast"
      "slack"
      "terminal-browser"
      "typora"
      "zed"
      "zoom"
    ];

    onActivation = {
      cleanup = "uninstall";
      upgrade = true;
    };
  };
}

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
      # Homebrew はmacOSアプリと、上流がTapを公式配布するCLIに限定する。
      HOMEBREW_FORBIDDEN_TAPS = "homebrew/core";
      HOMEBREW_NO_ANALYTICS = "1";
    };

    taps = {
      "k1LoW/homebrew-tap" = inputs.homebrew-k1low-tap;
      "stablyai/orca" = inputs.homebrew-stablyai-orca-tap;
    };

    trust.formulae = [ "k1LoW/tap/mo" ];
  };

  homebrew = {
    enable = true;

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
      "stablyai/orca/orca"
      "typora"
      "zoom"
    ];

    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = true;
    };
  };
}

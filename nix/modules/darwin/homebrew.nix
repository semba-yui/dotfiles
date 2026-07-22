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
    };

    trust.formulae = [ "k1LoW/tap/mo" ];
  };

  homebrew = {
    enable = true;

    brews = [ "k1LoW/tap/mo" ];

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

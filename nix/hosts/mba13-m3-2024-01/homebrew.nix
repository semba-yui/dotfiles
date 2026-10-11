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
      "karabiner-elements"
      "google-japanese-ime"
      "google-chrome"
    ];

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };
  };
}

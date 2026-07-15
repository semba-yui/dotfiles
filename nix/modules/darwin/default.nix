{ pkgs, ... }:

{
  environment.shells = [ pkgs.fish ];

  nix.settings.experimental-features = [
    "flakes"
    "nix-command"
  ];

  nixpkgs.config.allowUnfreePredicate = (
    pkg:
    builtins.elem (pkgs.lib.getName pkg) [
      "acli"
      "chatgpt"
      "claude-code"
      "discord"
      "git-fork"
      "google-chrome"
      "jetbrains-toolbox"
      "orbstack"
      "raycast"
      "slack"
      "teams"
      "zoom"
    ]
  );

  programs.fish.enable = true;
}

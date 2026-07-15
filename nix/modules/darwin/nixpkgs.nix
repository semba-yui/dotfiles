{ pkgs, ... }:

{
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
}

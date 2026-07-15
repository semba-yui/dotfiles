{ pkgs, ... }:

{
  # すべての unfree パッケージは許可せず、この構成で管理するものだけを明示的に許可する。
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

{ user, pkgs, ... }:

{

  home.username = "semba";
  home.homeDirectory = "/Users/semba";
  home.stateVersion = "26.05";

  imports = [
    ../../modules/home/programs/bat.nix
    ../../modules/home/programs/bottom.nix
    ../../modules/home/programs/claude-code.nix
    ../../modules/home/programs/codex.nix
    ../../modules/home/programs/delta.nix
    ../../modules/home/programs/direnv.nix
    ../../modules/home/programs/discord.nix
    ../../modules/home/programs/eza.nix
    ../../modules/home/programs/fd.nix
    ../../modules/home/programs/fish.nix
    ../../modules/home/programs/fzf.nix
    ../../modules/home/programs/gh.nix
    ../../modules/home/programs/git.nix
    ../../modules/home/programs/jq.nix
    ../../modules/home/programs/mise.nix
    ../../modules/home/programs/ripgrep.nix
    ../../modules/home/programs/zed-editor.nix
  ];

  home.packages = with pkgs; [
    acli
    ast-grep
    chatgpt
    cmux
    curl
    deadnix
    drawio
    dust
    ffmpeg
    ghq
    git-fork
    google-chrome
    gopls
    hyperfine
    jetbrains-mono
    jetbrains-toolbox
    mermaid-cli
    nil
    nixd
    nixfmt
    nix-output-monitor
    orbstack
    pcre2
    pyright
    raycast
    rust-analyzer
    sd
    slack
    statix
    teams
    tokei
    tree
    typescript
    typescript-language-server
    unzip
    yq
    wget
    zoom-us
  ];

  home.file = {
  };

  home.sessionVariables = {
  };

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

  programs.home-manager.enable = true;
}

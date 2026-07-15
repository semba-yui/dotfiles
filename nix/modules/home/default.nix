{ pkgs, ... }:

{
  imports = [
    ./programs/bat.nix
    ./programs/bottom.nix
    ./programs/claude-code.nix
    ./programs/codex.nix
    ./programs/delta.nix
    ./programs/direnv.nix
    ./programs/discord.nix
    ./programs/eza.nix
    ./programs/fd.nix
    ./programs/fish.nix
    ./programs/fzf.nix
    ./programs/gh.nix
    ./programs/git.nix
    ./programs/jq.nix
    ./programs/mise.nix
    ./programs/ripgrep.nix
    ./programs/zed-editor.nix
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
    wget
    yq
    zoom-us
  ];

  programs.home-manager.enable = true;
}

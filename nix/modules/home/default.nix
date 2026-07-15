{ pkgs, ... }:

{
  imports = [
    ./programs/bat.nix
    ./programs/betterleaks.nix
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
    ./programs/neovim.nix
    ./programs/ripgrep.nix
    ./programs/zed-editor.nix
  ];

  home.packages = with pkgs; [
    acli
    ast-grep
    bun
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
    hyperfine
    jdk25
    jetbrains-mono
    jetbrains-toolbox
    mermaid-cli
    nil
    nixd
    nixfmt
    nix-output-monitor
    nodejs
    orbstack
    pcre2
    python3
    pyright
    raycast
    sd
    slack
    statix
    teams
    tokei
    tree
    typescript
    typescript-language-server
    unzip
    uv
    wget
    yq
    zoom-us
  ];

  programs.home-manager.enable = true;
}

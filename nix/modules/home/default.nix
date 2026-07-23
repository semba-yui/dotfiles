{ pkgs, ... }:

{
  imports = [
    ./programs/apm.nix
    ./programs/bat.nix
    ./programs/betterleaks.nix
    ./programs/bottom.nix
    ./programs/claude-code.nix
    ./programs/codex.nix
    ./programs/delta.nix
    ./programs/direnv.nix
    ./programs/dotfiles.nix
    ./programs/eza.nix
    ./programs/fd.nix
    ./programs/fish.nix
    ./programs/fzf.nix
    ./programs/gh.nix
    ./programs/ghostty.nix
    ./programs/git-credential-manager.nix
    ./programs/git-worktree-runner.nix
    ./programs/git.nix
    ./programs/herdr.nix
    ./programs/jq.nix
    ./programs/lazygit.nix
    ./programs/mise.nix
    ./programs/neovim.nix
    ./programs/nh.nix
    ./programs/ripgrep.nix
    ./programs/xcodes.nix
    ./programs/zed-editor.nix
    ./programs/zoxide.nix
  ];

  home.packages = with pkgs; [
    acli
    ast-grep
    bun
    cmux
    curl
    deadnix
    dust
    ffmpeg
    ghq
    hunk
    hyperfine
    jdk25
    just
    mermaid-cli
    nerd-fonts.jetbrains-mono
    nil
    nixd
    nixfmt
    nix-output-monitor
    nodejs
    oxfmt
    pcre2
    python3
    pyright
    sd
    statix
    tokei
    tree
    typescript
    typescript-language-server
    unzip
    uv
    wget
    yq
  ];

  programs.home-manager.enable = true;
}

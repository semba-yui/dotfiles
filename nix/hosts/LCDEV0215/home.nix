{ pkgs, ... }:

{
  imports = [
    ../../modules/home/programs/agent-skills.nix
    ../../modules/home/programs/alloy.nix
    ../../modules/home/programs/apm.nix
    ../../modules/home/programs/bat.nix
    ../../modules/home/programs/bottom.nix
    ../../modules/home/programs/bun.nix
    ../../modules/home/programs/claude-code.nix
    ../../modules/home/programs/codex.nix
    ../../modules/home/programs/delta.nix
    ../../modules/home/programs/direnv.nix
    ../../modules/home/programs/eza.nix
    ../../modules/home/programs/fd.nix
    ../../modules/home/programs/fish.nix
    ../../modules/home/programs/fsautocomplete.nix
    ../../modules/home/programs/fzf.nix
    ../../modules/home/programs/ghostty.nix
    ../../modules/home/programs/git-worktree-runner.nix
    ../../modules/home/programs/github-copilot-cli.nix
    ../../modules/home/programs/glab.nix
    ../../modules/home/programs/herdr.nix
    ../../modules/home/programs/java.nix
    ../../modules/home/programs/jq.nix
    ../../modules/home/programs/jujutsu.nix
    ../../modules/home/programs/neovim.nix
    ../../modules/home/programs/nix-index.nix
    ../../modules/home/programs/orca.nix
    ../../modules/home/programs/ripgrep.nix
    ../../modules/home/programs/teamwork-graph-cli.nix
    ../../modules/home/programs/uv.nix
    ../../modules/home/programs/xcodes.nix
    ../../modules/home/programs/zed-editor.nix
    ../../modules/home/programs/zoxide.nix
  ];

  home = {
    stateVersion = "26.05";

    packages = with pkgs; [
      android-tools
      ast-grep
      curl
      dust
      ffmpeg
      hunk
      hyperfine
      just
      mermaid-cli
      nerd-fonts.jetbrains-mono
      nix-output-monitor
      nodejs
      oxfmt
      pcre2
      python3
      pyright
      sd
      tokei
      tree
      typescript
      typescript-language-server
      unzip
      wget
      yq
    ];
  };
}

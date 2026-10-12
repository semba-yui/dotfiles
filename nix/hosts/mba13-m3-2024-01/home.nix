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
    ../../modules/home/programs/fzf.nix
    ../../modules/home/programs/ghostty.nix
    ../../modules/home/programs/git-worktree-runner.nix
    ../../modules/home/programs/herdr-plugins.nix
    ../../modules/home/programs/herdr.nix
    ../../modules/home/programs/jq.nix
    ../../modules/home/programs/karabiner-us.nix
    ../../modules/home/programs/neovim.nix
    ../../modules/home/programs/nix-index.nix
    ../../modules/home/programs/orbstack.nix
    ../../modules/home/programs/ripgrep.nix
    ../../modules/home/programs/secure-enclave-signing.nix
    ../../modules/home/programs/terminal-code.nix
    ../../modules/home/programs/zed-editor.nix
    ../../modules/home/programs/zoxide.nix
  ];

  home = {
    stateVersion = "26.05";

    packages = with pkgs; [
      curl
      ffmpeg
      hyperfine
      mermaid-cli
      nerd-fonts.jetbrains-mono
      python3
      tree
      yq
    ];
  };

  programs.zed-editor.extensions = [ "nix" ];

  programs.zsh.enable = true;
}

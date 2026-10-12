{ lib, ... }:

{
  imports = [
    ../../modules/home/programs/alloy.nix
    ../../modules/home/programs/apm.nix
    ../../modules/home/programs/bat.nix
    ../../modules/home/programs/claude-code.nix
    ../../modules/home/programs/codex.nix
    ../../modules/home/programs/delta.nix
    ../../modules/home/programs/eza.nix
    ../../modules/home/programs/fd.nix
    ../../modules/home/programs/fish.nix
    ../../modules/home/programs/fzf.nix
    ../../modules/home/programs/ghostty.nix
    ../../modules/home/programs/git-worktree-runner.nix
    ../../modules/home/programs/herdr.nix
    ../../modules/home/programs/jq.nix
    ../../modules/home/programs/karabiner-us.nix
    ../../modules/home/programs/mise.nix
    ../../modules/home/programs/neovim.nix
    ../../modules/home/programs/ripgrep.nix
    ../../modules/home/programs/zed-editor.nix
    ../../modules/home/programs/zoxide.nix
  ];

  home.stateVersion = "26.05";

  programs.zed-editor.extensions = [ "nix" ];

  programs.zsh.enable = true;

  # 新MacにはまだSSH署名鍵が存在しない。
  programs.git.settings.commit.gpgsign = lib.mkForce false;
}

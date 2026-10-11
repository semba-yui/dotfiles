{
  homeDirectory,
  lib,
  pkgs,
  username,
  ...
}:

{
  imports = [
    ../../modules/home/programs/alloy.nix
    ../../modules/home/programs/apm.nix
    ../../modules/home/programs/bat.nix
    ../../modules/home/programs/betterleaks.nix
    ../../modules/home/programs/claude-code.nix
    ../../modules/home/programs/codex.nix
    ../../modules/home/programs/delta.nix
    ../../modules/home/programs/dotfiles.nix
    ../../modules/home/programs/eza.nix
    ../../modules/home/programs/fd.nix
    ../../modules/home/programs/fish.nix
    ../../modules/home/programs/fzf.nix
    ../../modules/home/programs/ghostty.nix
    ../../modules/home/programs/git-credential-manager.nix
    ../../modules/home/programs/git-worktree-runner.nix
    ../../modules/home/programs/git.nix
    ../../modules/home/programs/herdr.nix
    ../../modules/home/programs/jq.nix
    ../../modules/home/programs/karabiner-us.nix
    ../../modules/home/programs/lefthook.nix
    ../../modules/home/programs/mise.nix
    ../../modules/home/programs/neovim.nix
    ../../modules/home/programs/nh.nix
    ../../modules/home/programs/zed-editor.nix
    ../../modules/home/programs/zoxide.nix
  ];

  programs.zed-editor.extensions = [ "nix" ];

  home = {
    inherit homeDirectory username;
    stateVersion = "26.05";

    sessionPath = [ "$HOME/.local/bin" ];

    packages = with pkgs; [
      gh
      ghq
      ripgrep
      nixd
      nixfmt
    ];
  };

  programs.zsh.enable = true;

  # 新MacにはまだSSH署名鍵が存在しない。
  programs.git.settings.commit.gpgsign = lib.mkForce false;

  programs.home-manager.enable = true;
}

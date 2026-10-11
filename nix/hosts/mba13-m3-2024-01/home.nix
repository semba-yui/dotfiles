{
  homeDirectory,
  lib,
  pkgs,
  username,
  ...
}:

{
  imports = [
    ../../modules/home/programs/codex.nix
    ../../modules/home/programs/git.nix
    ../../modules/home/programs/nh.nix
    ../../modules/home/programs/dotfiles.nix
    ../../modules/home/programs/claude-code.nix
    ../../modules/home/programs/karabiner-us.nix
    ../../modules/home/programs/zed-editor.nix
    ../../modules/home/programs/git-credential-manager.nix
  ];

  programs.zed-editor.extensions = [ "nix" ];

  home = {
    inherit homeDirectory username;
    stateVersion = "26.05";

    sessionPath = [ "$HOME/.local/bin" ];

    packages = with pkgs; [
      gh
      ghq
      fzf
      ripgrep
      nixd
      nixfmt
    ];
  };

  programs.zsh.enable = true;

  # 新MacにはまだSSH署名鍵が存在しない。
  programs.git.settings.commit.gpgsign = lib.mkForce false;

  # Neovimを導入するまではmacOS標準エディタを使用する。
  programs.git.settings.core.editor = lib.mkForce "vi";

  programs.home-manager.enable = true;
}

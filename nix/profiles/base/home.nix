{
  homeDirectory,
  pkgs,
  username,
  ...
}:

# この dotfiles を clone して編集・検証・適用し、GitHub へ安全に push するのに必要なものだけを置く。
{
  imports = [
    ../../modules/home/programs/betterleaks.nix
    ../../modules/home/programs/dotfiles.nix
    ../../modules/home/programs/gh.nix
    ../../modules/home/programs/git-credential-manager.nix
    ../../modules/home/programs/git.nix
    ../../modules/home/programs/lefthook.nix
    ../../modules/home/programs/nh.nix
  ];

  home = {
    inherit homeDirectory username;

    # Claude Code や Codex など、公式インストーラーが置く起動用リンクを使えるようにする。
    sessionPath = [ "$HOME/.local/bin" ];

    packages = with pkgs; [
      ghq
      nixd
      nixfmt
    ];
  };

  programs.home-manager.enable = true;
}

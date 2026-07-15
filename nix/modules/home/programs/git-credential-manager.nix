{ pkgs, ... }:
{
  home.packages = [ pkgs.git-credential-manager ];

  programs.git.settings.credential.helper = [
    # system Git の osxkeychain を引き継がず、OAuth と複数アカウントに対応する GCM へ一本化する。
    ""
    "${pkgs.git-credential-manager}/bin/git-credential-manager"
  ];
}

{ pkgs, ... }:
{
  programs.mise = {
    enable = true;

    # nixpkgs-unstable の mise 2026.10.3 は、npm バックエンドが内蔵する CA 一覧に鍵が漏れた eMudhra の
    # ルートを含む。修正した 2026.10.17 以降が nixpkgs-unstable に届くまで公式のバイナリを使い、
    # 届いたらこの行と packages/mise.nix を消して pkgs.mise に戻す。
    package = pkgs.callPackage ../../../packages/mise.nix { };
  };
}

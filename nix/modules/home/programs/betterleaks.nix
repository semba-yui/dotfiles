{ pkgs, ... }:
{
  # このリポジトリの lefthook hook から呼ぶために PATH へ置く。
  # 端末全体の git hook として強制する意図はない。以前はグローバルな core.hooksPath で
  # 全リポジトリに効かせていたが、それが各リポジトリの .git/hooks を丸ごと無効化した。
  home.packages = [ pkgs.betterleaks ];
}

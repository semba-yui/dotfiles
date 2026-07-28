{ pkgs, ... }:
{
  # git hook の導入先を .git/hooks に限定するために使う。
  # lefthook install は core.hooksPath を書き換えないので、リポジトリごとの hook 運用を
  # 奪わない。設定は各リポジトリが持つ lefthook.yml 側に閉じ、この端末は実行系だけを供給する。
  # home-manager に programs.lefthook モジュールは無いため home.packages で入れる。
  home.packages = [ pkgs.lefthook ];
}

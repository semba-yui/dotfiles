{ ... }:

{
  # home.packages 直置きだと shell init が走らず z/zi が使えないため、モジュール管理にする。
  # fish 統合はデフォルト有効（config.fish で `zoxide init fish | source`）。
  programs.zoxide.enable = true;
}

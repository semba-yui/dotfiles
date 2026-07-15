{
  system.defaults.dock = {
    # 画面領域を広く使いつつ、必要なときだけDockへアクセスできるようにする。
    autohide = true;

    # ポインターを画面端へ移動した際の待ち時間だけをなくし、表示アニメーションは残す。
    autohide-delay = 0.0;

    # 最小化したウインドウをアプリのアイコンへまとめ、Dockの項目が増え続けるのを防ぐ。
    minimize-to-application = true;

    # 利用履歴によってSpacesの並びが変わらないようにし、位置を予測可能に保つ。
    mru-spaces = false;

    # 起動していない最近使用したアプリを表示せず、明示的に置いた項目を中心に保つ。
    show-recents = false;

    # 非表示中のアプリを半透明にし、起動状態と表示状態を区別しやすくする。
    showhidden = true;
  };

  # 右下へポインターを移動しただけでクイックメモが開く誤操作を防ぐ。
  # 専用オプションは正の整数しか受け付けないため、無効を表す0だけを汎用設定で宣言する。
  system.defaults.CustomUserPreferences."com.apple.dock"."wvous-br-corner" = 0;
}

{
  security.pam.services.sudo_local = {
    # Herdr の永続セッション内でも、Touch ID が参照するログインセッションへ接続し直す。
    reattach = true;

    # sudo の認証を省略せず、Touch ID で管理操作を承認できるようにする。
    touchIdAuth = true;
  };

  # ダウンロードしたアプリを Gatekeeper の検証対象として維持する。
  system.defaults.LaunchServices.LSQuarantine = true;
}

{
  security.pam.services.sudo_local = {
    # Herdr の永続セッション内でも、Touch ID が参照するログインセッションへ接続し直す。
    reattach = true;

    # sudo の認証を省略せず、Touch ID で管理操作を承認できるようにする。
    touchIdAuth = true;
  };

  # ダウンロードしたアプリを Gatekeeper の検証対象として維持する。
  system.defaults.LaunchServices.LSQuarantine = true;

  # eMudhra の中間 CA の秘密鍵が漏れたため、Mozilla は NSS 3.131.1 でこの 3 つのルートを外した。
  # nixpkgs-unstable の cacert がその版に届くまで、Nix のツールが読む CA 一覧から先に外しておく。
  # 届いたあとは元の一覧にこの名前がなくなり、何も外さなくなる。
  # Node・Bun・uv のように自前の CA 一覧を持つツールには効かない。
  security.pki.caCertificateBlacklist = [
    "emSign ECC Root CA - C3"
    "emSign ECC Root CA - G3"
    "emSign Root CA - C1"
  ];
}

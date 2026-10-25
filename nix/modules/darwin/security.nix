{ config, pkgs, ... }:

let
  # nix-darwin の pki モジュールと同じ引数で作るため、/etc/ssl/certs/ca-certificates.crt と同じ cacert になる。
  blacklistedCacert = pkgs.cacert.override {
    blacklist = config.security.pki.caCertificateBlacklist;
  };
  tlsOnlyCaBundle = "ssl/certs/ca-certificates-tls-only.crt";
in
{
  security.pam.services.sudo_local = {
    # Herdr の永続セッション内でも、Touch ID が参照するログインセッションへ接続し直す。
    reattach = true;

    # sudo の認証を省略せず、Touch ID で管理操作を承認できるようにする。
    touchIdAuth = true;
  };

  # ダウンロードしたアプリを Gatekeeper の検証対象として維持する。
  system.defaults.LaunchServices.LSQuarantine = true;

  # 秘密鍵が漏れた eMudhra の中間 CA には Comodo AAA Services root からの相互署名がある。NSS はこのルートを
  # メール用にしか信頼しないが、メール用の信頼を TLS にも使う実装（LibreSSL）があるため外す。
  # cacert は元の一覧にない名前があるとビルドを止めるので、NSS が既に外したルート（emSign など）は書かない。
  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root"
  ];

  # ca-certificates.crt の信頼設定付きの証明書は、OpenSSL 以外では読み飛ばされる（rustls）か、
  # メール用の信頼が TLS にも使われる（LibreSSL）。信頼設定を持たない TLS 用の一覧を別に置き、
  # OpenSSL 以外のツールにはこちらを渡す。security.pki.certificates で足した CA はここに入らない。
  environment.etc.${tlsOnlyCaBundle}.source =
    "${blacklistedCacert}/etc/ssl/certs/ca-no-trust-rules-bundle.crt";

  environment.variables = {
    # CA 一覧を内蔵するツール（uv、公式ビルドの Node など）も、Nix の cacert と blacklist に従わせる。
    # Bun は SSL_CERT_FILE を読まないため、ここでは守れない。
    SSL_CERT_FILE = "/etc/${tlsOnlyCaBundle}";

    # pip と requests は SSL_CERT_FILE を読まない。
    REQUESTS_CA_BUNDLE = "/etc/${tlsOnlyCaBundle}";

    # Claude Code が子プロセスへ渡す NODE_USE_SYSTEM_CA=1 と --use-openssl-ca が重なると Node が起動しないため、
    # --no-use-system-ca で打ち消す。NODE_OPTIONS を自前で上書きするスクリプトの中では効かない。
    NODE_OPTIONS = "--no-use-system-ca --use-openssl-ca";
  };
}

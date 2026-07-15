{
  networking.applicationFirewall = {
    # 必要なサービスをアプリ単位で許可できるよう、一律遮断は行わない。
    blockAllIncoming = false;
    enable = true;

    # 未許可の探索へ応答しにくくしつつ、許可済みサービスの通信は維持する。
    enableStealthMode = true;

    # Gatekeeper で検証されたアプリと macOS 組み込み機能は、更新後も自動で許可する。
    allowSigned = true;
    allowSignedApp = true;
  };
}

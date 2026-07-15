{
  system.defaults = {
    # ファイル種別を名前だけで誤認しないよう、すべてのアプリで拡張子を表示する。
    NSGlobalDomain.AppleShowAllExtensions = true;

    finder = {
      # 開発用の設定ファイルを Finder から確認できるよう、隠しファイルを表示する。
      AppleShowAllFiles = true;

      # 現在位置を把握し、親ディレクトリへ移動しやすいようパスバーを表示する。
      ShowPathbar = true;
    };
  };
}

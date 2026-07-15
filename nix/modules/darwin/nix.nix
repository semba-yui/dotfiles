{
  nix = {
    # 不具合は適用後すぐ検知して戻す運用のため、rollback できる期間を 1 週間に限定する。
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };

    optimise.automatic = true;

    settings.experimental-features = [
      "flakes"
      "nix-command"
    ];
  };
}

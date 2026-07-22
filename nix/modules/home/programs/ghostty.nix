{ pkgs, ... }:

{
  programs.ghostty = {
    enable = true;

    # nixpkgsのソースビルド版はLinux専用のため、公式macOS DMGをhash固定したパッケージを使う。
    package = pkgs.ghostty-bin;

    # Ghostty自身がFishを検出して統合するため、Home Managerから同じスクリプトを重ねて読み込まない。
    enableFishIntegration = false;

    settings = {
      auto-update = "off";
      confirm-close-surface = true;
      copy-on-select = true;
      font-family = "JetBrainsMono Nerd Font Mono";
      macos-option-as-alt = true;
      macos-titlebar-style = "tabs";
      # 長いビルドログを遡れるよう、タブ・splitごとの上限を50MBへ増やす。
      scrollback-limit = 50000000;
      shell-integration = "fish";
      theme = "Catppuccin Mocha";
    };
  };
}

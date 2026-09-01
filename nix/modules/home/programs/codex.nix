{ pkgs, ... }:
{
  programs.codex = {
    enable = true;

    # nixpkgs の codex は Rust ソースからビルドするため上流リリース当日には追随できない。
    # packages/codex-release.json で公式の署名済み配布物を直接固定した派生を使う。
    package = pkgs.callPackage ../../../packages/codex.nix { };

    # ユーザー指示は動的状態ではないため、Home Managerの標準オプションで正本を配置する。
    # config.tomlはproject trustや端末固有パスが混在するため、settingsでは管理しない。
    context = ../../../../codex/.codex/AGENTS.md;
  };
}

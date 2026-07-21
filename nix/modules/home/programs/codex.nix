{ ... }:
{
  programs.codex = {
    enable = true;

    # ユーザー指示は動的状態ではないため、Home Managerの標準オプションで正本を配置する。
    # config.tomlはproject trustや端末固有パスが混在するため、settingsでは管理しない。
    context = ../../../../codex/.codex/AGENTS.md;
  };
}
